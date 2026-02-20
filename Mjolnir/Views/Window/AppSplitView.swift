import AppKit
import SwiftUI
import SwiftData

struct AppSplitView<Sidebar: View, Content: View, Inspector: View>: NSViewControllerRepresentable {
    @Binding var isSidebarVisible: Bool
    @Binding var isInspectorVisible: Bool

    @ViewBuilder var sidebar: Sidebar
    @ViewBuilder var content: Content
    @ViewBuilder var inspector: Inspector

    @Environment(\.modelContext) private var modelContext

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

        // Content panel — plain background
        let contentVC = NSViewController()
        contentVC.view = NSView()
        embedHostingView(
            rootView: content.ignoresSafeArea().modelContainer(container),
            in: contentVC.view
        )
        let contentItem = NSSplitViewItem(viewController: contentVC)
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

        return splitVC
    }

    func updateNSViewController(_ splitVC: NSSplitViewController, context: Context) {
        guard splitVC.splitViewItems.count == 3 else { return }

        let sidebarItem = splitVC.splitViewItems[0]
        if sidebarItem.isCollapsed == isSidebarVisible {
            sidebarItem.animator().isCollapsed = !isSidebarVisible
        }

        let inspectorItem = splitVC.splitViewItems[2]
        if inspectorItem.isCollapsed == isInspectorVisible {
            inspectorItem.animator().isCollapsed = !isInspectorVisible
        }
    }

    // MARK: - Helpers

    private func embedHostingView<V: View>(rootView: V, in parent: NSView) {
        let hosting = NSHostingView(rootView: rootView)
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
