import AppKit

class SidebarViewController: NSViewController {
    override func loadView() {
        // NSVisualEffectView as the root — Big Sur Finder sidebar look
        let effectView = NSVisualEffectView()
        effectView.material = .sidebar
        effectView.blendingMode = .behindWindow
        effectView.state = .followsWindowActiveState

        let label = NSTextField(labelWithString: "Sidebar")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .secondaryLabelColor
        effectView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: effectView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: effectView.centerYAnchor),
        ])

        self.view = effectView
    }
}
