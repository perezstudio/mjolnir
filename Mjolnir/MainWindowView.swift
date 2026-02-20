import SwiftUI
import SwiftData

struct MainWindowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appState = AppState()
    @State private var terminalManager = TerminalManager()

    var body: some View {
        AppSplitView(
            isSidebarVisible: $appState.isSidebarVisible,
            isInspectorVisible: $appState.isInspectorVisible,
            sidebar: {
                SidebarView(appState: appState, onPickFolder: presentFolderPicker)
            },
            content: {
                ChatSplitView(
                    isBottomVisible: $appState.isTerminalVisible,
                    top: {
                        ChatView(appState: appState, terminalManager: terminalManager)
                    },
                    bottom: {
                        TerminalAreaRepresentable(terminalManager: terminalManager, appState: appState)
                    }
                )
            },
            inspector: {
                InspectorView(appState: appState)
            }
        )
        .ignoresSafeArea()
        .edgeToEdgeWindow()
        .frame(minWidth: 900, minHeight: 600)
        .onChange(of: appState.isTerminalVisible) { _, visible in
            if visible, terminalManager.sessions.isEmpty,
               let chat = appState.selectedChat {
                terminalManager.addSession(workingDirectory: chat.workingDirectory)
            }
        }
    }

    // MARK: - Folder Picker

    private func presentFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a project folder"
        panel.prompt = "Add Project"

        guard let window = NSApp.keyWindow else { return }

        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url else { return }
            addProject(from: url)
        }
    }

    private func addProject(from url: URL) {
        let context = ModelContext(modelContext.container)
        let name = url.lastPathComponent
        let path = url.path

        let viewModel = SidebarViewModel()
        viewModel.createProject(name: name, path: path, modelContext: context)

        let fetchDescriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.path == path },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let project = try? context.fetch(fetchDescriptor).first {
            appState.selectedProject = project
        }
    }
}
