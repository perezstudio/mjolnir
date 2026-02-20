import AppKit
import SwiftUI

struct ChatSplitView<Top: View, Bottom: View>: NSViewControllerRepresentable {
    @Binding var isBottomVisible: Bool

    @ViewBuilder var top: Top
    @ViewBuilder var bottom: Bottom

    class Coordinator {
        var lastBottomVisible: Bool?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSViewController(context: Context) -> NSSplitViewController {
        let splitVC = NSSplitViewController()
        splitVC.splitView.isVertical = false // vertical stack (top / bottom)
        splitVC.splitView.dividerStyle = .thin

        // Top: main content
        let topVC = NSViewController()
        topVC.view = NSView()
        embedHostingView(rootView: top.ignoresSafeArea(), in: topVC.view)
        let topItem = NSSplitViewItem(viewController: topVC)
        topItem.minimumThickness = 200
        splitVC.addSplitViewItem(topItem)

        // Bottom: collapsible panel
        let bottomVC = NSViewController()
        bottomVC.view = NSView()
        embedHostingView(rootView: bottom.ignoresSafeArea(), in: bottomVC.view)
        let bottomItem = NSSplitViewItem(viewController: bottomVC)
        bottomItem.canCollapse = true
        bottomItem.isCollapsed = !isBottomVisible
        bottomItem.minimumThickness = 80
        splitVC.addSplitViewItem(bottomItem)

        context.coordinator.lastBottomVisible = isBottomVisible

        return splitVC
    }

    func updateNSViewController(_ splitVC: NSSplitViewController, context: Context) {
        guard splitVC.splitViewItems.count == 2 else { return }
        let coord = context.coordinator

        if coord.lastBottomVisible != isBottomVisible {
            coord.lastBottomVisible = isBottomVisible
            let visible = isBottomVisible
            DispatchQueue.main.async {
                splitVC.splitViewItems[1].isCollapsed = !visible
            }
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
