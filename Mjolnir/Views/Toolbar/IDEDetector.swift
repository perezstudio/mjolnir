import AppKit

struct IDEDetector {

    struct InstalledApp {
        let name: String
        let bundleID: String
        let url: URL
    }

    private static let candidates: [(String, String)] = [
        ("Xcode", "com.apple.dt.Xcode"),
        ("VS Code", "com.microsoft.VSCode"),
        ("Cursor", "com.todesktop.230313mzl4w4u92"),
        ("Windsurf", "com.codeium.windsurf"),
        ("iTerm2", "com.googlecode.iterm2"),
        ("Terminal", "com.apple.Terminal"),
    ]

    static func detectInstalled() -> [InstalledApp] {
        candidates.compactMap { name, bundleID in
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
                return nil
            }
            return InstalledApp(name: name, bundleID: bundleID, url: url)
        }
    }

    static func open(bundleID: String, path: String) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.open(
            [URL(fileURLWithPath: path)],
            withApplicationAt: appURL,
            configuration: config
        )
    }

    static func revealInFinder(path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }
}
