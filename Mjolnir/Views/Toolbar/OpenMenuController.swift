import AppKit

final class OpenMenuController {

    static func showMenu(for path: String, relativeTo view: NSView) {
        let menu = NSMenu()

        // Reveal in Finder
        let revealHandler = MenuActionHandler {
            IDEDetector.revealInFinder(path: path)
        }
        let revealItem = NSMenuItem(
            title: "Reveal in Finder",
            action: #selector(MenuActionHandler.perform(_:)),
            keyEquivalent: ""
        )
        revealItem.target = revealHandler
        revealItem.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
        menu.addItem(revealItem)

        menu.addItem(.separator())

        // Dynamically add installed IDEs
        let installed = IDEDetector.detectInstalled()
        var handlers: [MenuActionHandler] = [revealHandler]

        for app in installed {
            let handler = MenuActionHandler {
                IDEDetector.open(bundleID: app.bundleID, path: path)
            }
            handlers.append(handler)

            let item = NSMenuItem(
                title: "Open in \(app.name)",
                action: #selector(MenuActionHandler.perform(_:)),
                keyEquivalent: ""
            )
            item.target = handler

            let icon = NSWorkspace.shared.icon(forFile: app.url.path)
            icon.size = NSSize(width: 16, height: 16)
            item.image = icon

            menu.addItem(item)
        }

        // Store handlers to keep them alive for the menu's lifetime
        objc_setAssociatedObject(menu, "handlers", handlers, .OBJC_ASSOCIATION_RETAIN)

        let point = NSPoint(x: 0, y: view.bounds.height)
        menu.popUp(positioning: nil, at: point, in: view)
    }
}

// MARK: - Menu Action Handler

private final class MenuActionHandler: NSObject {
    let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    @objc func perform(_ sender: Any?) {
        action()
    }
}
