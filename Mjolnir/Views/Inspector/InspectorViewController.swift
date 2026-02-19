import AppKit

class InspectorViewController: NSViewController {
    override func loadView() {
        // NSVisualEffectView for the inspector — matches sidebar vibrancy
        let effectView = NSVisualEffectView()
        effectView.material = .sidebar
        effectView.blendingMode = .behindWindow
        effectView.state = .followsWindowActiveState

        let label = NSTextField(labelWithString: "Inspector")
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
