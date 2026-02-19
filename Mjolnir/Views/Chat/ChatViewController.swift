import AppKit

class ChatViewController: NSViewController {
    override func loadView() {
        let view = NSView()
        view.wantsLayer = true
        // Solid background for the main content area
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        let label = NSTextField(labelWithString: "Chat")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .secondaryLabelColor
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        self.view = view
    }
}
