import Foundation

actor GitWorktreeManager {

    private let worktreeBaseDir = ".mjolnir/worktrees"

    // MARK: - Worktree Lifecycle

    func createWorktree(
        projectPath: String,
        chatId: UUID,
        baseBranch: String? = nil
    ) async throws -> (worktreePath: String, branchName: String) {
        let branch = "mjolnir/\(chatId.uuidString.lowercased().prefix(8))"
        let worktreePath = (projectPath as NSString)
            .appendingPathComponent("\(worktreeBaseDir)/\(chatId.uuidString)")

        // Resolve the base branch (default to current HEAD)
        let base = try baseBranch ?? currentBranch(at: projectPath)

        // Create the worktree with a new branch
        try runGit(
            args: ["worktree", "add", "-b", branch, worktreePath, base],
            at: projectPath
        )

        return (worktreePath, branch)
    }

    func removeWorktree(
        projectPath: String,
        worktreePath: String,
        branchName: String?
    ) async throws {
        // Remove the worktree
        try runGit(
            args: ["worktree", "remove", "--force", worktreePath],
            at: projectPath
        )

        // Delete the branch if specified
        if let branch = branchName {
            try? runGit(
                args: ["branch", "-D", branch],
                at: projectPath
            )
        }
    }

    // MARK: - Gitignore

    func ensureGitignore(projectPath: String) throws {
        let gitignorePath = (projectPath as NSString).appendingPathComponent(".gitignore")
        let entry = ".mjolnir/"

        if FileManager.default.fileExists(atPath: gitignorePath) {
            let contents = try String(contentsOfFile: gitignorePath, encoding: .utf8)
            let lines = contents.components(separatedBy: .newlines)
            if lines.contains(where: { $0.trimmingCharacters(in: .whitespaces) == entry }) {
                return // Already present
            }
            // Append the entry
            let separator = contents.hasSuffix("\n") ? "" : "\n"
            try (contents + separator + entry + "\n").write(toFile: gitignorePath, atomically: true, encoding: .utf8)
        } else {
            try (entry + "\n").write(toFile: gitignorePath, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Helpers

    func currentBranch(at projectPath: String) throws -> String {
        let output = try runGit(args: ["rev-parse", "--abbrev-ref", "HEAD"], at: projectPath)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

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
            throw GitWorktreeError.gitCommandFailed(
                command: "git \(args.joined(separator: " "))",
                stderr: errorOutput,
                exitCode: process.terminationStatus
            )
        }

        return output
    }
}

enum GitWorktreeError: LocalizedError {
    case gitCommandFailed(command: String, stderr: String, exitCode: Int32)

    var errorDescription: String? {
        switch self {
        case .gitCommandFailed(let command, let stderr, let exitCode):
            return "Git command failed (\(exitCode)): \(command)\n\(stderr)"
        }
    }
}
