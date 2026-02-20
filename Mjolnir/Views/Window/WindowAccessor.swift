import SwiftUI
import AppKit

// MARK: - Title Bar Metrics

struct TitleBarMetrics {
    let height: CGFloat
    let trafficLightInset: CGFloat

    static let standard = TitleBarMetrics(
        height: 52,
        trafficLightInset: 78
    )
}

private struct TitleBarMetricsKey: EnvironmentKey {
    static let defaultValue = TitleBarMetrics.standard
}

extension EnvironmentValues {
    var titleBarMetrics: TitleBarMetrics {
        get { self[TitleBarMetricsKey.self] }
        set { self[TitleBarMetricsKey.self] = newValue }
    }
}

// MARK: - Window Accessor

private class WindowAccessorView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window = window else { return }

        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = true
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        WindowAccessorView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    func edgeToEdgeWindow() -> some View {
        self.background(WindowAccessor())
    }
}
