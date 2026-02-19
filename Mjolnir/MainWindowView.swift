import SwiftUI

struct MainWindowView: View {
    var body: some View {
        WindowRepresentable()
            .ignoresSafeArea()
            .frame(minWidth: 900, minHeight: 600)
            .toolbar(removing: .title)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
    }
}
