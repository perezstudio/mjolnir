import AppKit
import SwiftUI
import SwiftData

class ChatViewController: NSViewController {

    var modelContainer: ModelContainer?
    var appState: AppState?

    private var hostingView: NSHostingView<AnyView>?

    override func loadView() {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHostingView()
    }

    private func setupHostingView() {
        guard let modelContainer, let appState else { return }

        let chatView = ChatView(appState: appState)
            .ignoresSafeArea()
            .modelContainer(modelContainer)

        let hosting = NSHostingView(rootView: AnyView(chatView))
        hosting.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        self.hostingView = hosting
    }
}
