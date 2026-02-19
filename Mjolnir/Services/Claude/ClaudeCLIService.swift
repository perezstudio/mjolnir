import Foundation

actor ClaudeCLIService {
    private var currentProcess: Process?
    private let decoder = JSONDecoder()

    // MARK: - CLI Discovery

    nonisolated func findClaudeBinary() -> String? {
        let commonPaths = [
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            "\(NSHomeDirectory())/.local/bin/claude",
            "\(NSHomeDirectory())/.npm-global/bin/claude",
        ]

        for path in commonPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        // Fall back to `which`
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["claude"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let path, !path.isEmpty, process.terminationStatus == 0 {
                return path
            }
        } catch {}

        return nil
    }

    nonisolated func isClaudeInstalled() -> Bool {
        findClaudeBinary() != nil
    }

    // MARK: - Send Message

    func sendMessage(
        prompt: String,
        model: String? = nil,
        workingDirectory: String,
        sessionID: String? = nil,
        continueSession: Bool = false,
        systemPrompt: String? = nil,
        maxTurns: Int? = nil,
        maxBudgetUsd: Double? = nil,
        allowedTools: [String]? = nil,
        permissionMode: String? = nil
    ) -> AsyncThrowingStream<CLIMessage, Error> {
        let claudePath = findClaudeBinary()

        return AsyncThrowingStream { continuation in
            guard let claudePath else {
                continuation.finish(throwing: ClaudeCLIError.cliNotFound)
                return
            }

            let task = Task {
                do {
                    try await self.runCLI(
                        claudePath: claudePath,
                        prompt: prompt,
                        model: model,
                        workingDirectory: workingDirectory,
                        sessionID: sessionID,
                        continueSession: continueSession,
                        systemPrompt: systemPrompt,
                        maxTurns: maxTurns,
                        maxBudgetUsd: maxBudgetUsd,
                        allowedTools: allowedTools,
                        permissionMode: permissionMode,
                        continuation: continuation
                    )
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
                Task { await self.cancel() }
            }
        }
    }

    // MARK: - Cancel

    func cancel() {
        currentProcess?.terminate()
        currentProcess = nil
    }

    // MARK: - Internal

    private func runCLI(
        claudePath: String,
        prompt: String,
        model: String?,
        workingDirectory: String,
        sessionID: String?,
        continueSession: Bool,
        systemPrompt: String?,
        maxTurns: Int?,
        maxBudgetUsd: Double?,
        allowedTools: [String]?,
        permissionMode: String?,
        continuation: AsyncThrowingStream<CLIMessage, Error>.Continuation
    ) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: claudePath)
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)

        var arguments = [
            "-p", prompt,
            "--output-format", "stream-json",
            "--verbose",
        ]

        if let model {
            arguments += ["--model", model]
        }
        if let sessionID {
            arguments += ["--resume", sessionID]
        }
        if continueSession {
            arguments += ["--continue"]
        }
        if let systemPrompt {
            arguments += ["--system-prompt", systemPrompt]
        }
        if let maxTurns {
            arguments += ["--max-turns", String(maxTurns)]
        }
        if let maxBudgetUsd {
            arguments += ["--max-budget-usd", String(maxBudgetUsd)]
        }
        if let allowedTools, !allowedTools.isEmpty {
            arguments += ["--allowedTools", allowedTools.joined(separator: ",")]
        }
        if let permissionMode {
            arguments += ["--permission-mode", permissionMode]
        }

        process.arguments = arguments

        // Strip CLAUDECODE env var so we can spawn from within Claude Code
        var env = ProcessInfo.processInfo.environment
        env.removeValue(forKey: "CLAUDECODE")
        env.removeValue(forKey: "CLAUDE_CODE")
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        self.currentProcess = process

        try process.run()

        let stdoutHandle = stdoutPipe.fileHandleForReading

        // Read stdout line-by-line, each line is a JSON object
        for try await line in stdoutHandle.bytes.lines {
            if Task.isCancelled { break }

            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            guard let data = trimmed.data(using: .utf8) else { continue }

            do {
                let message = try decoder.decode(CLIMessage.self, from: data)
                continuation.yield(message)
            } catch {
                // Skip unparseable lines rather than crashing the stream
                continue
            }
        }

        process.waitUntilExit()
        self.currentProcess = nil

        let exitCode = process.terminationStatus
        if exitCode != 0 {
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrString = String(data: stderrData, encoding: .utf8) ?? ""
            if !stderrString.isEmpty {
                continuation.finish(throwing: ClaudeCLIError.processError(exitCode: exitCode, stderr: stderrString))
                return
            }
        }

        continuation.finish()
    }
}

// MARK: - Errors

enum ClaudeCLIError: LocalizedError {
    case cliNotFound
    case processError(exitCode: Int32, stderr: String)
    case notLoggedIn

    var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "Claude CLI not found. Install it from https://claude.ai/download"
        case .processError(let code, let stderr):
            return "Claude CLI exited with code \(code): \(stderr)"
        case .notLoggedIn:
            return "Not logged in. Run 'claude login' in your terminal."
        }
    }
}
