import AppKit

class MainSplitViewController: NSSplitViewController {

    private let sidebarVC = SidebarViewController()
    private let chatVC = ChatViewController()
    private let inspectorVC = InspectorViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarVC)
        sidebarItem.canCollapse = true
        sidebarItem.minimumThickness = 220
        sidebarItem.maximumThickness = 350

        let contentItem = NSSplitViewItem(viewController: chatVC)
        contentItem.minimumThickness = 400

        let inspectorItem = NSSplitViewItem(inspectorWithViewController: inspectorVC)
        inspectorItem.canCollapse = true
        inspectorItem.minimumThickness = 250
        inspectorItem.maximumThickness = 400
        inspectorItem.isCollapsed = true

        addSplitViewItem(sidebarItem)
        addSplitViewItem(contentItem)
        addSplitViewItem(inspectorItem)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        configureWindow()
    }

    private func configureWindow() {
        guard let window = view.window else { return }
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
    }
}
