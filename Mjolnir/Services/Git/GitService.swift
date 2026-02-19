import Foundation

// MARK: - Git File Status

struct GitFileStatus: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let indexStatus: Character
    let workTreeStatus: Character

    var displayStatus: FileChangeStatus {
        if workTreeStatus == "?" { return .untracked }
        if workTreeStatus == "D" || indexStatus == "D" { return .deleted }
        if workTreeStatus == "A" || indexStatus == "A" { return .added }
        if indexStatus == "R" { return .renamed }
        return .modified
    }

    var isStaged: Bool {
        indexStatus != " " && indexStatus != "?"
    }
}

enum FileChangeStatus: String {
    case added = "A"
    case modified = "M"
    case deleted = "D"
    case untracked = "?"
    case renamed = "R"

    var label: String { rawValue }
}

// MARK: - Git Service

actor GitService {

    func currentBranch(at workingDirectory: String) throws -> String {
        let output = try runGit(args: ["rev-parse", "--abbrev-ref", "HEAD"], at: workingDirectory)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func status(at workingDirectory: String) throws -> [GitFileStatus] {
        let output = try runGit(args: ["status", "--porcelain=v1"], at: workingDirectory)
        return output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { line -> GitFileStatus? in
                guard line.count >= 4 else { return nil }
                let indexChar = line[line.startIndex]
                let workTreeChar = line[line.index(after: line.startIndex)]
                let path = String(line.dropFirst(3))
                return GitFileStatus(
                    path: path,
                    indexStatus: indexChar,
                    workTreeStatus: workTreeChar
                )
            }
    }

    func diff(file: String?, staged: Bool = false, at workingDirectory: String) throws -> String {
        var args = ["diff"]
        if staged { args.append("--cached") }
        args.append("--no-color")
        if let file { args.append(file) }
        return try runGit(args: args, at: workingDirectory)
    }

    func stageFile(_ file: String, at workingDirectory: String) throws {
        try runGit(args: ["add", file], at: workingDirectory)
    }

    func commit(files: [String], message: String, at workingDirectory: String) throws {
        for file in files {
            try runGit(args: ["add", file], at: workingDirectory)
        }
        try runGit(args: ["commit", "-m", message], at: workingDirectory)
    }

    func commitsAhead(at workingDirectory: String) throws -> Int {
        // Check if there's an upstream tracking branch
        let branch = try currentBranch(at: workingDirectory)
        let upstream: String
        do {
            upstream = try runGit(
                args: ["rev-parse", "--abbrev-ref", "\(branch)@{upstream}"],
                at: workingDirectory
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return 0 // No upstream configured
        }
        let output = try runGit(
            args: ["rev-list", "--count", "\(upstream)..HEAD"],
            at: workingDirectory
        )
        return Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    func push(at workingDirectory: String) throws {
        try runGit(args: ["push"], at: workingDirectory)
    }

    func generateDiffSummary(at workingDirectory: String) throws -> String {
        let diffStat = try runGit(args: ["diff", "--cached", "--stat"], at: workingDirectory)
        let diffContent = try runGit(args: ["diff", "--cached", "--no-color"], at: workingDirectory)
        // If nothing staged, get unstaged diff
        if diffContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let unstagedStat = try runGit(args: ["diff", "--stat"], at: workingDirectory)
            let unstagedDiff = try runGit(args: ["diff", "--no-color"], at: workingDirectory)
            return "Diff stat:\n\(unstagedStat)\n\nDiff:\n\(unstagedDiff)"
        }
        return "Diff stat:\n\(diffStat)\n\nDiff:\n\(diffContent)"
    }

    func discardChanges(files: [String], at workingDirectory: String) throws {
        let allStatus = try status(at: workingDirectory)
        let untrackedPaths = Set(allStatus.filter { $0.workTreeStatus == "?" }.map(\.path))

        let tracked = files.filter { !untrackedPaths.contains($0) }
        let untracked = files.filter { untrackedPaths.contains($0) }

        if !tracked.isEmpty {
            try runGit(args: ["checkout", "--"] + tracked, at: workingDirectory)
        }
        for path in untracked {
            let fullPath = (workingDirectory as NSString).appendingPathComponent(path)
            try? FileManager.default.removeItem(atPath: fullPath)
        }
    }

    // MARK: - Private

    @discardableResult
    private func runGit(args: [String], at workingDirectory: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)

        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown git error"
            throw GitServiceError.commandFailed(
                command: "git \(args.joined(separator: " "))",
                stderr: errorOutput,
                exitCode: process.terminationStatus
            )
        }

        return output
    }
}

enum GitServiceError: LocalizedError {
    case commandFailed(command: String, stderr: String, exitCode: Int32)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let stderr, let exitCode):
            return "Git command failed (\(exitCode)): \(command)\n\(stderr)"
        }
    }
}
