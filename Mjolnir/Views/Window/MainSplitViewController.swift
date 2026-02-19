import AppKit

class MainSplitViewController: NSSplitViewController {

    private let sidebarVC = SidebarViewController()
    private let chatVC = ChatViewController()
    private let inspectorVC = InspectorViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Use plain viewController init for ALL items to avoid system sidebar/inspector styling
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
        configureWindow()
    }

    private func configureWindow() {
        guard let window = view.window else { return }

        // Remove the titlebar entirely — content owns the full window
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        // Hide the toolbar so SwiftUI/AppKit don't inject one
        window.toolbar = nil

        // Hide titlebar traffic-light buttons' background
        window.standardWindowButton(.closeButton)?.superview?.superview?.isHidden = false

        // Move traffic lights down a bit so they sit nicely in the sidebar header area
        if let closeButton = window.standardWindowButton(.closeButton) {
            closeButton.superview?.frame.origin.y = -4
        }
    }
}
