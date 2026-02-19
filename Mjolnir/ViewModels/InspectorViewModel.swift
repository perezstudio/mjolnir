import Foundation

enum InspectorTab: String, CaseIterable {
    case files = "Files"
    case modified = "Modified"
}

@Observable
final class InspectorViewModel {

    // MARK: - State

    var selectedTab: InspectorTab = .files
    var fileTree: FileNode?
    var modifiedFiles: [GitFileStatus] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // Diff
    var selectedFilePath: String?
    var selectedDiff: String?
    var showingDiff: Bool {
        get { selectedDiff != nil }
        set { if !newValue { clearDiff() } }
    }

    // Commit
    var commitMessage: String = ""
    var commitsAhead: Int = 0
    var isPushing: Bool = false
    var isGeneratingMessage: Bool = false

    // Discard
    var showingDiscardConfirmation: Bool = false

    // MARK: - Dependencies

    private let gitService = GitService()
    private let fileSystemService = FileSystemService()
    private let cliService = ClaudeCLIService()

    // MARK: - Refresh

    func refresh(workingDirectory: String) {
        guard !workingDirectory.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                async let treeResult = fileSystemService.buildFileTree(at: workingDirectory)
                async let statusResult = gitService.status(at: workingDirectory)
                async let aheadResult = gitService.commitsAhead(at: workingDirectory)

                let tree = try await treeResult
                let status = try await statusResult
                let ahead = try await aheadResult

                self.fileTree = tree
                self.modifiedFiles = status
                self.commitsAhead = ahead
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    // MARK: - Diff

    func loadDiff(for file: GitFileStatus, workingDirectory: String) {
        selectedFilePath = file.path
        Task {
            do {
                let diffText = try await gitService.diff(
                    file: file.path,
                    staged: file.isStaged,
                    at: workingDirectory
                )
                self.selectedDiff = diffText.isEmpty
                    ? "(No diff available -- file may be untracked)"
                    : diffText
            } catch {
                self.selectedDiff = "Error loading diff: \(error.localizedDescription)"
            }
        }
    }

    func clearDiff() {
        selectedFilePath = nil
        selectedDiff = nil
    }

    // MARK: - Commit

    func performCommit(workingDirectory: String) {
        let files = modifiedFiles.map(\.path)
        let message = commitMessage
        guard !files.isEmpty, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        Task {
            do {
                try await gitService.commit(files: files, message: message, at: workingDirectory)
                commitMessage = ""
                refresh(workingDirectory: workingDirectory)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Generate Commit Message

    func generateCommitMessage(workingDirectory: String) {
        guard !isGeneratingMessage else { return }
        isGeneratingMessage = true

        Task {
            do {
                // Stage all files first so diff --cached works
                let files = modifiedFiles.map(\.path)
                for file in files {
                    try await gitService.stageFile(file, at: workingDirectory)
                }

                let diffSummary = try await gitService.generateDiffSummary(at: workingDirectory)
                let prompt = "Generate a concise git commit message (1-2 lines) for these changes. Return ONLY the commit message text, nothing else.\n\n\(diffSummary)"

                var generatedText = ""
                let stream = await cliService.sendMessage(
                    prompt: prompt,
                    model: "claude-haiku-4-5-20251001",
                    workingDirectory: workingDirectory,
                    permissionMode: "plan"
                )

                for try await message in stream {
                    switch message {
                    case .streamEvent(let event):
                        if case .contentBlockDelta(let delta) = event.event,
                           case .textDelta(let text) = delta.delta {
                            generatedText += text
                        }
                    case .assistant(let msg):
                        if generatedText.isEmpty {
                            generatedText = msg.message.textContent
                        }
                    case .result:
                        break
                    default:
                        break
                    }
                }

                let cleaned = generatedText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty {
                    self.commitMessage = cleaned
                }
            } catch {
                self.errorMessage = "Failed to generate message: \(error.localizedDescription)"
            }
            self.isGeneratingMessage = false
        }
    }

    // MARK: - Push

    func push(workingDirectory: String) {
        guard !isPushing, commitsAhead > 0 else { return }
        isPushing = true

        Task {
            do {
                try await gitService.push(at: workingDirectory)
                self.commitsAhead = 0
            } catch {
                errorMessage = error.localizedDescription
            }
            self.isPushing = false
        }
    }

    // MARK: - Discard

    func performDiscard(workingDirectory: String) {
        let files = modifiedFiles.map(\.path)
        guard !files.isEmpty else { return }

        Task {
            do {
                try await gitService.discardChanges(files: files, at: workingDirectory)
                showingDiscardConfirmation = false
                refresh(workingDirectory: workingDirectory)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
