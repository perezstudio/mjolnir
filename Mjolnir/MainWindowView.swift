import SwiftUI

struct MainWindowView: View {
    @State private var appState = AppState()

    var body: some View {
        WindowRepresentable(appState: appState)
            .ignoresSafeArea()
            .edgeToEdgeWindow()
            .frame(minWidth: 900, minHeight: 600)
    }
}
