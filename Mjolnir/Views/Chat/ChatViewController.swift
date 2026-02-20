import AppKit
import SwiftUI
import SwiftData

class ChatViewController: NSSplitViewController {

    var modelContainer: ModelContainer? {
        didSet { setupIfReady() }
    }
    var appState: AppState? {
        didSet { setupIfReady() }
    }

    private let terminalManager = TerminalManager()
    private let chatContentVC = NSViewController()
    private let terminalAreaVC = TerminalAreaSplitViewController()
    private var terminalItem: NSSplitViewItem!
    private var isSetUp = false
    private var observationTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.isVertical = false // vertical stack (top / bottom)
        splitView.dividerStyle = .thin
        setupIfReady()
    }

    private func setupIfReady() {
        guard !isSetUp, isViewLoaded, let modelContainer, let appState else { return }
        isSetUp = true

        // Top: chat content
        setupChatContent(modelContainer: modelContainer, appState: appState)
        let chatItem = NSSplitViewItem(viewController: chatContentVC)
        chatItem.minimumThickness = 200
        addSplitViewItem(chatItem)

        // Bottom: terminal area (collapsible)
        terminalAreaVC.terminalManager = terminalManager
        terminalAreaVC.appState = appState
        terminalItem = NSSplitViewItem(viewController: terminalAreaVC)
        terminalItem.canCollapse = true
        terminalItem.isCollapsed = true
        terminalItem.minimumThickness = 80
        addSplitViewItem(terminalItem)

        startObserving(appState: appState)
    }

    private func setupChatContent(modelContainer: ModelContainer, appState: AppState) {
        let hosting = NSHostingView(rootView: ChatView(appState: appState, terminalManager: terminalManager)
            .ignoresSafeArea()
            .modelContainer(modelContainer)
        )
        hosting.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        chatContentVC.view = container
    }

    // MARK: - Observation

    private func startObserving(appState: AppState) {
        observationTask?.cancel()
        observationTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }

                let shouldShow = appState.isTerminalVisible
                if terminalItem.isCollapsed == shouldShow {
                    terminalItem.animator().isCollapsed = !shouldShow
                }

                // Auto-create first terminal when shown
                if shouldShow, terminalManager.sessions.isEmpty,
                   let chat = appState.selectedChat {
                    terminalManager.addSession(workingDirectory: chat.workingDirectory)
                }

                await withCheckedContinuation { continuation in
                    withObservationTracking {
                        _ = appState.isTerminalVisible
                    } onChange: {
                        continuation.resume()
                    }
                }
            }
        }
    }
}
