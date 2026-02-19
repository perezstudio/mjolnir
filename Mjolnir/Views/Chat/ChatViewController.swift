import AppKit

class ChatViewController: NSViewController {
    override func loadView() {
        let view = NSView()
        view.wantsLayer = true

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
