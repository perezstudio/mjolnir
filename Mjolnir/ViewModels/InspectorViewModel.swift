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
    var diffState = DiffState()

    // Commit
    var commitMessage: String = ""
    var commitsAhead: Int = 0
    var isPushing: Bool = false
    var isGeneratingMessage: Bool = false

    // Discard
    var showingDiscardConfirmation: Bool = false

    // MARK: - Dependencies

    private let gitService = GitService.shared
    private let fileSystemService = FileSystemService()
    private let cliService = ClaudeCLIService.shared
    private var watchingDirectory: String?

    // MARK: - File Watching

    func startWatching(workingDirectory: String) {
        guard !workingDirectory.isEmpty, watchingDirectory != workingDirectory else { return }
        stopWatching()
        watchingDirectory = workingDirectory

        Task {
            await fileSystemService.startWatching(path: workingDirectory) { [weak self] in
                Task { @MainActor in
                    self?.refresh(workingDirectory: workingDirectory)
                }
            }
        }
    }

    func stopWatching() {
        guard watchingDirectory != nil else { return }
        watchingDirectory = nil
        Task {
            await fileSystemService.stopWatching()
        }
    }

    // MARK: - Refresh

    func refresh(workingDirectory: String) {
        guard !workingDirectory.isEmpty else { return }
        let isInitialLoad = fileTree == nil
        if isInitialLoad {
            isLoading = true
        }
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
                if status.map(\.path) != modifiedFiles.map(\.path)
                    || status.map(\.displayStatus) != modifiedFiles.map(\.displayStatus) {
                    self.modifiedFiles = status
                }
                self.commitsAhead = ahead
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    // MARK: - Diff

    func loadDiff(for file: GitFileStatus, workingDirectory: String) {
        Task {
            do {
                let oldContent: String
                if file.isUntracked {
                    oldContent = ""
                } else {
                    oldContent = (try? await gitService.fileContent(
                        path: file.path,
                        revision: "HEAD",
                        at: workingDirectory
                    )) ?? ""
                }

                let newContent: String
                if file.displayStatus == .deleted {
                    newContent = ""
                } else {
                    newContent = (try? await gitService.workingCopyContent(
                        path: file.path,
                        at: workingDirectory
                    )) ?? ""
                }

                self.diffState.filePath = file.path
                self.diffState.oldContent = oldContent
                self.diffState.newContent = newContent
                self.diffState.isReady = true
            } catch {
                self.errorMessage = "Failed to load diff: \(error.localizedDescription)"
            }
        }
    }

    func clearDiff() {
        diffState.isReady = false
        diffState.filePath = ""
        diffState.oldContent = ""
        diffState.newContent = ""
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

// MARK: - Diff State (shared between InspectorView and DiffView window)

@Observable
final class DiffState {
    var filePath: String = ""
    var oldContent: String = ""
    var newContent: String = ""
    var isReady: Bool = false
}
