import AppKit
import SwiftUI
import SwiftData

class InspectorViewController: NSViewController {

    var modelContainer: ModelContainer?
    var appState: AppState?

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHostingView()
    }

    private func setupHostingView() {
        guard let modelContainer, let appState else { return }

        let hosting = NSHostingView(rootView: InspectorView(appState: appState)
            .background(.ultraThinMaterial)
            .ignoresSafeArea()
            .modelContainer(modelContainer)
        )
        hosting.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}
