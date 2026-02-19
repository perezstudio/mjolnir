import AppKit
import SwiftUI
import SwiftTerm

// MARK: - Contained Split View (prevents divider events from propagating to parent NSSplitView)

private class ContainedSplitView: NSSplitView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Let this split view fully claim hits within its bounds,
        // preventing the parent NSSplitView from intercepting divider drags.
        let result = super.hitTest(point)
        if result != nil, bounds.contains(convert(point, from: superview)) {
            return result
        }
        return result
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
    }
}

// MARK: - Terminal Area Split (sidebar | terminal content)

class TerminalAreaSplitViewController: NSSplitViewController {

    var terminalManager: TerminalManager?
    var appState: AppState?

    private let sidebarVC = NSViewController()
    private let contentVC = TerminalContentViewController()

    override func loadView() {
        let split = ContainedSplitView()
        split.isVertical = true
        split.dividerStyle = .thin
        self.splitView = split
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let terminalManager, let appState else { return }

        // Left: session list
        setupSidebar(terminalManager: terminalManager, appState: appState)
        let sidebarItem = NSSplitViewItem(viewController: sidebarVC)
        sidebarItem.minimumThickness = 80
        sidebarItem.maximumThickness = 300
        addSplitViewItem(sidebarItem)

        // Right: terminal content
        contentVC.terminalManager = terminalManager
        let contentItem = NSSplitViewItem(viewController: contentVC)
        contentItem.minimumThickness = 200
        addSplitViewItem(contentItem)
    }

    private func setupSidebar(terminalManager: TerminalManager, appState: AppState) {
        let listView = TerminalSessionListView(manager: terminalManager, appState: appState)
        let hosting = NSHostingView(rootView: AnyView(listView))
        hosting.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        sidebarVC.view = container
    }
}

// MARK: - Terminal Content (manages LocalProcessTerminalView instances)

class TerminalContentViewController: NSViewController, LocalProcessTerminalViewDelegate {

    var terminalManager: TerminalManager?

    private var terminals: [UUID: LocalProcessTerminalView] = [:]
    private var viewToSession: [ObjectIdentifier: UUID] = [:]
    private var currentTheme: TerminalTheme?
    private var observationTask: Task<Void, Never>?

    override func loadView() {
        let v = NSView()
        v.wantsLayer = true
        v.autoresizesSubviews = true
        self.view = v
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        startObserving()
    }

    private func startObserving() {
        observationTask?.cancel()
        observationTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, let manager = self.terminalManager else { return }

                self.syncTerminals(manager: manager)

                await withCheckedContinuation { continuation in
                    withObservationTracking {
                        _ = manager.sessions
                        _ = manager.sessions.map(\.pendingCommand)
                        _ = manager.activeSessionID
                        _ = manager.theme
                    } onChange: {
                        continuation.resume()
                    }
                }
            }
        }
    }

    private func syncTerminals(manager: TerminalManager) {
        let sessions = manager.sessions
        let activeID = manager.activeSessionID
        let theme = manager.theme

        // Add new sessions
        for session in sessions {
            if terminals[session.id] == nil {
                let termView = LocalProcessTerminalView(frame: view.bounds)
                termView.processDelegate = self
                termView.autoresizingMask = [.width, .height]
                applyTheme(theme, to: termView)
                view.addSubview(termView)
                terminals[session.id] = termView
                viewToSession[ObjectIdentifier(termView)] = session.id

                let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
                let shellName = "-" + (shell as NSString).lastPathComponent
                let dir = session.workingDirectory.isEmpty ? nil : session.workingDirectory
                termView.startProcess(executable: shell, execName: shellName, currentDirectory: dir)

                if let command = session.pendingCommand {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let bytes = Array((command + "\n").utf8)
                        termView.send(source: termView, data: bytes[...])
                        session.pendingCommand = nil
                    }
                }
            } else if let command = session.pendingCommand,
                      let termView = terminals[session.id] {
                let bytes = Array((command + "\n").utf8)
                termView.send(source: termView, data: bytes[...])
                session.pendingCommand = nil
            }
        }

        // Remove deleted sessions
        let currentIDs = Set(sessions.map(\.id))
        for (id, termView) in terminals where !currentIDs.contains(id) {
            termView.terminate()
            termView.removeFromSuperview()
            viewToSession.removeValue(forKey: ObjectIdentifier(termView))
            terminals.removeValue(forKey: id)
        }

        // Show only active, update frames
        for (id, termView) in terminals {
            let isActive = id == activeID
            termView.isHidden = !isActive
            if isActive {
                termView.frame = view.bounds
            }
        }

        // Apply theme if changed
        if currentTheme != theme {
            currentTheme = theme
            for (_, termView) in terminals {
                applyTheme(theme, to: termView)
            }
        }
    }

    private func applyTheme(_ theme: TerminalTheme, to termView: LocalProcessTerminalView) {
        termView.nativeBackgroundColor = theme.backgroundColor
        termView.nativeForegroundColor = theme.foregroundColor
        termView.caretColor = theme.caretColor
        termView.needsDisplay = true
    }

    // MARK: - LocalProcessTerminalViewDelegate

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        let viewID = ObjectIdentifier(source)
        guard let sessionID = viewToSession[viewID],
              let session = terminalManager?.sessions.first(where: { $0.id == sessionID }) else { return }
        session.title = title
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    func processTerminated(source: TerminalView, exitCode: Int32?) {}
}

// MARK: - Terminal Session List (SwiftUI)

struct TerminalSessionListView: View {
    @Bindable var manager: TerminalManager
    @Bindable var appState: AppState

    private var workingDirectory: String {
        appState.selectedChat?.workingDirectory ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Terminals")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()

                // Theme toggle
                Button {
                    manager.theme = manager.theme == .dark ? .light : .dark
                } label: {
                    Image(systemName: manager.theme == .dark ? "sun.max" : "moon")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(manager.theme == .dark ? "Switch to Light" : "Switch to Dark")

                Button {
                    manager.addSession(workingDirectory: workingDirectory)
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("New Terminal")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Divider()

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(manager.sessions) { session in
                        TerminalSessionRow(
                            session: session,
                            isActive: session.id == manager.activeSessionID,
                            onSelect: { manager.activeSessionID = session.id },
                            onClose: { manager.removeSession(id: session.id) }
                        )
                    }
                }
                .padding(4)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Session Row

struct TerminalSessionRow: View {
    let session: TerminalSession
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "terminal")
                .font(.caption2)
            Text(session.title)
                .font(.caption)
                .lineLimit(1)
            Spacer()
            if isActive || isHovered {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isActive ? Color.accentColor.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { isHovered = $0 }
    }
}
