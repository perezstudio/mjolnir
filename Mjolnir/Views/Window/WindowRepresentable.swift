import SwiftUI
import SwiftData

struct WindowRepresentable: NSViewControllerRepresentable {
    @Environment(\.modelContext) private var modelContext

    func makeNSViewController(context: Context) -> MainSplitViewController {
        let controller = MainSplitViewController()
        return controller
    }

    func updateNSViewController(_ nsViewController: MainSplitViewController, context: Context) {
    }
}
