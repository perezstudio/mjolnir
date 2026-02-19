import SwiftUI
import SwiftData

struct WindowRepresentable: NSViewControllerRepresentable {
    @Environment(\.modelContext) private var modelContext
    var appState: AppState

    func makeNSViewController(context: Context) -> MainSplitViewController {
        let controller = MainSplitViewController()
        controller.modelContainer = modelContext.container
        controller.appState = appState
        return controller
    }

    func updateNSViewController(_ nsViewController: MainSplitViewController, context: Context) {
    }
}
