import AppKit
import SwiftUI
import SwiftData

struct AppSplitView<Sidebar: View, Content: View, Inspector: View>: NSViewControllerRepresentable {
    @Binding var isSidebarVisible: Bool
    @Binding var isInspectorVisible: Bool
    @Binding var isTerminalVisible: Bool

    var terminalManager: TerminalManager
    var appState: AppState

    @ViewBuilder var sidebar: Sidebar
    @ViewBuilder var content: Content
    @ViewBuilder var inspector: Inspector

    @Environment(\.modelContext) private var modelContext

    class Coordinator {
        var lastSidebarVisible: Bool?
        var lastInspectorVisible: Bool?
        var lastTerminalVisible: Bool?
        var contentSplitVC: NSSplitViewController?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSViewController(context: Context) -> NSSplitViewController {
        let splitVC = NSSplitViewController()
        let container = modelContext.container

        // Sidebar panel — NSVisualEffectView background
        let sidebarVC = NSViewController()
        let sidebarEffect = NSVisualEffectView()
        sidebarEffect.material = .sidebar
        sidebarEffect.blendingMode = .behindWindow
        sidebarVC.view = sidebarEffect
        embedHostingView(
            rootView: sidebar.ignoresSafeArea().modelContainer(container),
            in: sidebarVC.view
        )
        let sidebarItem = NSSplitViewItem(viewController: sidebarVC)
        sidebarItem.canCollapse = true
        sidebarItem.minimumThickness = 220
        sidebarItem.maximumThickness = 350

        // Content panel — vertical split (chat + terminal)
        let contentSplitVC = NSSplitViewController()
        contentSplitVC.splitView.isVertical = false
        contentSplitVC.splitView.dividerStyle = .thin

        // Chat content (top)
        let chatVC = NSViewController()
        chatVC.view = NSView()
        embedHostingView(
            rootView: content.ignoresSafeArea().modelContainer(container),
            in: chatVC.view
        )
        let chatItem = NSSplitViewItem(viewController: chatVC)
        chatItem.minimumThickness = 200
        contentSplitVC.addSplitViewItem(chatItem)

        // Terminal area (bottom) — direct VC, no hosting view wrapper
        let terminalAreaVC = TerminalAreaSplitViewController()
        terminalAreaVC.terminalManager = terminalManager
        terminalAreaVC.appState = appState
        let terminalItem = NSSplitViewItem(viewController: terminalAreaVC)
        terminalItem.canCollapse = true
        terminalItem.isCollapsed = !isTerminalVisible
        terminalItem.minimumThickness = 80
        contentSplitVC.addSplitViewItem(terminalItem)

        context.coordinator.contentSplitVC = contentSplitVC

        let contentItem = NSSplitViewItem(viewController: contentSplitVC)
        contentItem.minimumThickness = 400

        // Inspector panel — NSVisualEffectView background
        let inspectorVC = NSViewController()
        let inspectorEffect = NSVisualEffectView()
        inspectorEffect.material = .sidebar
        inspectorEffect.blendingMode = .behindWindow
        inspectorVC.view = inspectorEffect
        embedHostingView(
            rootView: inspector.ignoresSafeArea().modelContainer(container),
            in: inspectorVC.view
        )
        let inspectorItem = NSSplitViewItem(viewController: inspectorVC)
        inspectorItem.canCollapse = true
        inspectorItem.minimumThickness = 250
        inspectorItem.maximumThickness = 400
        inspectorItem.isCollapsed = !isInspectorVisible

        splitVC.addSplitViewItem(sidebarItem)
        splitVC.addSplitViewItem(contentItem)
        splitVC.addSplitViewItem(inspectorItem)
        splitVC.splitView.dividerStyle = .thin

        context.coordinator.lastSidebarVisible = isSidebarVisible
        context.coordinator.lastInspectorVisible = isInspectorVisible
        context.coordinator.lastTerminalVisible = isTerminalVisible

        return splitVC
    }

    func updateNSViewController(_ splitVC: NSSplitViewController, context: Context) {
        guard splitVC.splitViewItems.count == 3 else { return }
        let coord = context.coordinator

        if coord.lastSidebarVisible != isSidebarVisible {
            coord.lastSidebarVisible = isSidebarVisible
            let visible = isSidebarVisible
            DispatchQueue.main.async {
                splitVC.splitViewItems[0].isCollapsed = !visible
            }
        }

        if coord.lastInspectorVisible != isInspectorVisible {
            coord.lastInspectorVisible = isInspectorVisible
            let visible = isInspectorVisible
            DispatchQueue.main.async {
                splitVC.splitViewItems[2].isCollapsed = !visible
            }
        }

        if coord.lastTerminalVisible != isTerminalVisible,
           let contentSplitVC = coord.contentSplitVC,
           contentSplitVC.splitViewItems.count == 2 {
            coord.lastTerminalVisible = isTerminalVisible
            let visible = isTerminalVisible
            DispatchQueue.main.async {
                contentSplitVC.splitViewItems[1].isCollapsed = !visible
            }
        }
    }

    // MARK: - Helpers

    private func embedHostingView<V: View>(rootView: V, in parent: NSView) {
        let hosting = NSHostingView(rootView: rootView)
        hosting.sizingOptions = []
        hosting.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: parent.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
        ])
    }
}
