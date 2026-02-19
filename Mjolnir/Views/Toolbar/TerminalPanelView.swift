import SwiftUI
import SwiftTerm

/// NSViewRepresentable that manages multiple LocalProcessTerminalView instances.
/// Each TerminalSession gets its own terminal view; only the active one is visible.
struct MultiTerminalView: NSViewRepresentable {
    let sessions: [TerminalSession]
    let activeSessionID: UUID?
    let theme: TerminalTheme

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.autoresizesSubviews = true
        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        let coordinator = context.coordinator

        // Add terminal views for new sessions
        for session in sessions {
            if coordinator.terminals[session.id] == nil {
                let termView = LocalProcessTerminalView(frame: container.bounds)
                termView.processDelegate = coordinator
                termView.autoresizingMask = [.width, .height]
                applyTheme(theme, to: termView)
                container.addSubview(termView)
                coordinator.terminals[session.id] = termView
                coordinator.viewToSession[ObjectIdentifier(termView)] = session.id

                let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
                let shellName = "-" + (shell as NSString).lastPathComponent
                let dir = session.workingDirectory.isEmpty ? nil : session.workingDirectory
                termView.startProcess(executable: shell, execName: shellName, currentDirectory: dir)

                // Deliver initial command after shell starts
                if let command = session.pendingCommand {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let bytes = Array((command + "\n").utf8)
                        termView.send(source: termView, data: bytes[...])
                        session.pendingCommand = nil
                    }
                }
            } else if let command = session.pendingCommand,
                      let termView = coordinator.terminals[session.id] {
                let bytes = Array((command + "\n").utf8)
                termView.send(source: termView, data: bytes[...])
                session.pendingCommand = nil
            }
        }

        // Remove terminal views for deleted sessions
        let currentIDs = Set(sessions.map(\.id))
        for (id, view) in coordinator.terminals where !currentIDs.contains(id) {
            view.terminate()
            view.removeFromSuperview()
            coordinator.viewToSession.removeValue(forKey: ObjectIdentifier(view))
            coordinator.terminals.removeValue(forKey: id)
        }

        // Show only the active terminal, update frames
        for (id, view) in coordinator.terminals {
            let isActive = id == activeSessionID
            view.isHidden = !isActive
            if isActive {
                view.frame = container.bounds
            }
        }

        // Apply theme if changed
        if coordinator.currentTheme != theme {
            coordinator.currentTheme = theme
            for (_, view) in coordinator.terminals {
                applyTheme(theme, to: view)
            }
        }

        coordinator.sessions = sessions
    }

    static func dismantleNSView(_ container: NSView, coordinator: Coordinator) {
        for (_, view) in coordinator.terminals {
            view.terminate()
        }
        coordinator.terminals.removeAll()
    }

    private func applyTheme(_ theme: TerminalTheme, to termView: LocalProcessTerminalView) {
        termView.nativeBackgroundColor = theme.backgroundColor
        termView.nativeForegroundColor = theme.foregroundColor
        termView.caretColor = theme.caretColor
        termView.needsDisplay = true
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var terminals: [UUID: LocalProcessTerminalView] = [:]
        var viewToSession: [ObjectIdentifier: UUID] = [:]
        var sessions: [TerminalSession] = []
        var currentTheme: TerminalTheme?

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            let viewID = ObjectIdentifier(source)
            guard let sessionID = viewToSession[viewID],
                  let session = sessions.first(where: { $0.id == sessionID }) else { return }
            session.title = title
        }

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

        func processTerminated(source: TerminalView, exitCode: Int32?) {}
    }
}
