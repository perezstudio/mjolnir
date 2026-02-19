import Foundation
import SwiftData

@Observable
final class SidebarViewModel {

    private let worktreeManager = GitWorktreeManager()

    // MARK: - Project CRUD

    func createProject(name: String, path: String, modelContext: ModelContext) {
        let project = Project(name: name, path: path)
        // Set sortOrder to end of list
        let fetchDescriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        let maxOrder = (try? modelContext.fetch(fetchDescriptor).first?.sortOrder) ?? -1
        project.sortOrder = maxOrder + 1
        modelContext.insert(project)
        try? modelContext.save()

        // Ensure .mjolnir/ is in .gitignore
        Task {
            try? await worktreeManager.ensureGitignore(projectPath: path)
        }
    }

    func deleteProject(_ project: Project, modelContext: ModelContext) {
        // Clean up worktrees for all chats
        let chatsWithWorktrees = project.chats.filter { $0.hasWorktree }
        if !chatsWithWorktrees.isEmpty {
            Task {
                for chat in chatsWithWorktrees {
                    if let wtPath = chat.worktreePath {
                        try? await worktreeManager.removeWorktree(
                            projectPath: project.path,
                            worktreePath: wtPath,
                            branchName: chat.branchName
                        )
                    }
                }
            }
        }

        modelContext.delete(project)
        try? modelContext.save()
    }

    func renameProject(_ project: Project, newName: String) {
        project.name = newName
        project.updatedAt = Date()
    }

    // MARK: - Chat CRUD

    func createChat(title: String, project: Project, modelContext: ModelContext) {
        let chat = Chat(title: title, project: project)
        chat.sortOrder = project.chats.count
        modelContext.insert(chat)
        try? modelContext.save()
    }

    func createWorktreeChat(
        title: String,
        project: Project,
        modelContext: ModelContext
    ) async throws {
        let chat = Chat(title: title, project: project)
        chat.hasWorktree = true
        chat.sortOrder = project.chats.count

        let result = try await worktreeManager.createWorktree(
            projectPath: project.path,
            chatId: chat.id
        )

        chat.worktreePath = result.worktreePath
        chat.branchName = result.branchName
        chat.baseBranch = try? await worktreeManager.currentBranch(at: project.path)

        modelContext.insert(chat)
        try? modelContext.save()
    }

    func deleteChat(_ chat: Chat, modelContext: ModelContext) {
        if chat.hasWorktree, let project = chat.project, let wtPath = chat.worktreePath {
            Task {
                try? await worktreeManager.removeWorktree(
                    projectPath: project.path,
                    worktreePath: wtPath,
                    branchName: chat.branchName
                )
            }
        }

        modelContext.delete(chat)
        try? modelContext.save()
    }

    func renameChat(_ chat: Chat, newTitle: String) {
        chat.title = newTitle
        chat.updatedAt = Date()
    }

    func duplicateChat(_ chat: Chat, modelContext: ModelContext) {
        guard let project = chat.project else { return }
        let newChat = Chat(title: "\(chat.title) (copy)", project: project)
        newChat.sortOrder = project.chats.count
        modelContext.insert(newChat)
        try? modelContext.save()
    }

    // MARK: - Reorder

    func moveChat(_ chat: Chat, toIndex newIndex: Int, within project: Project) {
        var sortedChats = project.chats.sorted { $0.sortOrder < $1.sortOrder }
        guard let oldIndex = sortedChats.firstIndex(where: { $0.id == chat.id }) else { return }
        sortedChats.remove(at: oldIndex)
        sortedChats.insert(chat, at: min(newIndex, sortedChats.count))
        for (index, c) in sortedChats.enumerated() {
            c.sortOrder = index
        }
    }
}
