import AppKit
import SwiftData

class MainSplitViewController: NSSplitViewController {

    let sidebarVC = SidebarViewController()
    private let chatVC = ChatViewController()
    private let inspectorVC = InspectorViewController()

    private var observationTask: Task<Void, Never>?

    var modelContainer: ModelContainer? {
        didSet {
            sidebarVC.modelContainer = modelContainer
            chatVC.modelContainer = modelContainer
            inspectorVC.modelContainer = modelContainer
        }
    }

    var appState: AppState? {
        didSet {
            sidebarVC.appState = appState
            chatVC.appState = appState
            inspectorVC.appState = appState
            startObservingPanelVisibility()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let sidebarItem = NSSplitViewItem(viewController: sidebarVC)
        sidebarItem.canCollapse = true
        sidebarItem.minimumThickness = 220
        sidebarItem.maximumThickness = 350

        let contentItem = NSSplitViewItem(viewController: chatVC)
        contentItem.minimumThickness = 400

        let inspectorItem = NSSplitViewItem(viewController: inspectorVC)
        inspectorItem.canCollapse = true
        inspectorItem.minimumThickness = 250
        inspectorItem.maximumThickness = 400
        inspectorItem.isCollapsed = true

        addSplitViewItem(sidebarItem)
        addSplitViewItem(contentItem)
        addSplitViewItem(inspectorItem)

        splitView.dividerStyle = .thin
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard let window = view.window else { return }
        window.titlebarSeparatorStyle = .none
        window.toolbar = nil
    }

    // MARK: - Panel Visibility Observation

    private func startObservingPanelVisibility() {
        observationTask?.cancel()
        observationTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, let appState = self.appState else { return }

                // Sync sidebar visibility
                let sidebarVisible = appState.isSidebarVisible
                if let sidebarItem = self.splitViewItems.first {
                    if sidebarItem.isCollapsed == sidebarVisible {
                        sidebarItem.animator().isCollapsed = !sidebarVisible
                    }
                }

                // Sync inspector visibility
                let inspectorVisible = appState.isInspectorVisible
                if let inspectorItem = self.splitViewItems.last {
                    if inspectorItem.isCollapsed == inspectorVisible {
                        inspectorItem.animator().isCollapsed = !inspectorVisible
                    }
                }

                await withCheckedContinuation { continuation in
                    withObservationTracking {
                        _ = appState.isSidebarVisible
                        _ = appState.isInspectorVisible
                    } onChange: {
                        continuation.resume()
                    }
                }
            }
        }
    }
}
