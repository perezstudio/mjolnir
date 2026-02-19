import AppKit
import SwiftData

class MainSplitViewController: NSSplitViewController {

    let sidebarVC = SidebarViewController()
    private let chatVC = ChatViewController()
    private let inspectorVC = InspectorViewController()

    var modelContainer: ModelContainer? {
        didSet {
            sidebarVC.modelContainer = modelContainer
            chatVC.modelContainer = modelContainer
        }
    }

    var appState: AppState? {
        didSet {
            sidebarVC.appState = appState
            chatVC.appState = appState
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
}
