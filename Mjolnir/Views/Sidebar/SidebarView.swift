import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.sortOrder) private var projects: [Project]
    @Bindable var appState: AppState

    @State private var viewModel = SidebarViewModel()
    @State private var renamingProject: Project?
    @State private var renamingChat: Chat?
    @State private var renameText = ""
    @State private var showDeleteConfirmation = false
    @State private var projectToDelete: Project?

    /// Callback to present NSOpenPanel from the hosting AppKit controller
    var onPickFolder: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            sidebarHeader
            projectList
        }
    }

    // MARK: - Header

    private var sidebarHeader: some View {
        HStack {
            // Space for traffic light buttons
            Spacer()

            Button {
                onPickFolder?()
            } label: {
                Image(systemName: "plus")
                    .fontWeight(.medium)
            }
            .buttonStyle(.plain)
            .help("Add Project")

            Button {
                appState.isSidebarVisible = false
            } label: {
                Image(systemName: "sidebar.leading")
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .help("Hide Sidebar")
        }
        .padding(.trailing, 12)
        .frame(height: 52) // Match titlebar height
    }

    // MARK: - Project List

    private var projectList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                if projects.isEmpty {
                    emptyState
                } else {
                    ForEach(projects) { project in
                        projectSection(for: project)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.plus")
                .imageScale(.large)
                .foregroundStyle(.tertiary)
            Text("No Projects")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Click + to add a project folder")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Project Section

    @ViewBuilder
    private func projectSection(for project: Project) -> some View {
        @Bindable var project = project
        DisclosureGroup(isExpanded: $project.isExpanded) {
            let sortedChats = project.chats.sorted { $0.sortOrder < $1.sortOrder }
            ForEach(sortedChats) { chat in
                chatRow(for: chat)
            }
        } label: {
            ProjectRowView(
                project: project,
                onNewChat: { createChat(in: project) },
                onNewWorktreeChat: { createWorktreeChat(in: project) },
                onRename: { beginRenameProject(project) },
                onDelete: {
                    projectToDelete = project
                    showDeleteConfirmation = true
                }
            )
        }
        .alert("Delete Project?", isPresented: $showDeleteConfirmation, presenting: projectToDelete) { proj in
            Button("Delete", role: .destructive) {
                viewModel.deleteProject(proj, modelContext: modelContext)
                if appState.selectedProject?.id == proj.id {
                    appState.selectedProject = nil
                    appState.selectedChat = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { proj in
            Text("This will delete \"\(proj.name)\" and all its chats. This cannot be undone.")
        }
    }

    // MARK: - Chat Row

    private func chatRow(for chat: Chat) -> some View {
        ChatRowView(
            chat: chat,
            isSelected: appState.selectedChat?.id == chat.id,
            onRename: { beginRenameChat(chat) },
            onDuplicate: { viewModel.duplicateChat(chat, modelContext: modelContext) },
            onDelete: {
                if appState.selectedChat?.id == chat.id {
                    appState.selectedChat = nil
                }
                viewModel.deleteChat(chat, modelContext: modelContext)
            }
        )
        .onTapGesture {
            appState.selectedProject = chat.project
            appState.selectedChat = chat
        }
    }

    // MARK: - Actions

    private func createChat(in project: Project) {
        let title = "New Chat"
        viewModel.createChat(title: title, project: project, modelContext: modelContext)
        project.isExpanded = true
        // Select the new chat
        if let newChat = project.chats.sorted(by: { $0.sortOrder < $1.sortOrder }).last {
            appState.selectedProject = project
            appState.selectedChat = newChat
        }
    }

    private func createWorktreeChat(in project: Project) {
        Task {
            do {
                try await viewModel.createWorktreeChat(
                    title: "New Worktree Chat",
                    project: project,
                    modelContext: modelContext
                )
                project.isExpanded = true
                if let newChat = project.chats.sorted(by: { $0.sortOrder < $1.sortOrder }).last {
                    appState.selectedProject = project
                    appState.selectedChat = newChat
                }
            } catch {
                print("Failed to create worktree chat: \(error)")
            }
        }
    }

    private func beginRenameProject(_ project: Project) {
        renameText = project.name
        renamingProject = project
    }

    private func beginRenameChat(_ chat: Chat) {
        renameText = chat.title
        renamingChat = chat
    }
}
