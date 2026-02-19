import AppKit
import SwiftUI
import SwiftData

class SidebarViewController: NSViewController {

    var modelContainer: ModelContainer?
    var appState: AppState?

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHostingView()
    }

    private func setupHostingView() {
        guard let modelContainer, let appState else { return }

        var sidebarView = SidebarView(appState: appState)
        sidebarView.onPickFolder = { [weak self] in
            self?.presentFolderPicker()
        }

        let hosting = NSHostingView(rootView: sidebarView
            .background(.ultraThinMaterial)
            .ignoresSafeArea()
            .modelContainer(modelContainer)
        )
        hosting.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Folder Picker

    private func presentFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a project folder"
        panel.prompt = "Add Project"

        guard let window = view.window else { return }

        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.addProject(from: url)
        }
    }

    private func addProject(from url: URL) {
        guard let modelContainer else { return }
        let context = ModelContext(modelContainer)
        let appState = self.appState

        let name = url.lastPathComponent
        let path = url.path

        let viewModel = SidebarViewModel()
        viewModel.createProject(name: name, path: path, modelContext: context)

        // Refresh to get the new project and select it
        let fetchDescriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.path == path },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let project = try? context.fetch(fetchDescriptor).first {
            appState?.selectedProject = project
        }
    }
}
