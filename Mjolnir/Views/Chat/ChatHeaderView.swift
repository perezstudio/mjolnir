import SwiftUI

struct ChatHeaderView: View {
    @Bindable var chat: Chat
    @Bindable var appState: AppState
    let isProcessing: Bool
    let onCancel: () -> Void
    var onRunCommand: (() -> Void)?
    var onConfigureRunCommand: (() -> Void)?

    @State private var isEditingTitle = false
    @State private var editedTitle = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    appState.isSidebarVisible.toggle()
                } label: {
                    Image(systemName: "sidebar.leading")
                        .foregroundStyle(appState.isSidebarVisible ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .help(appState.isSidebarVisible ? "Hide Sidebar" : "Show Sidebar")

                if isEditingTitle {
                    TextField("Chat title", text: $editedTitle)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                        .onSubmit {
                            chat.title = editedTitle
                            chat.updatedAt = Date()
                            isEditingTitle = false
                        }
                } else {
                    Text(chat.title)
                        .font(.headline)
                        .lineLimit(1)
                        .onTapGesture(count: 2) {
                            editedTitle = chat.title
                            isEditingTitle = true
                        }
                }

                if chat.hasWorktree, let branch = chat.branchName {
                    GitBranchBadge(branchName: branch)
                }

                Spacer()

                // Terminal toggle
                Button {
                    appState.isTerminalVisible.toggle()
                } label: {
                    Image(systemName: "terminal")
                        .foregroundStyle(appState.isTerminalVisible ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .help(appState.isTerminalVisible ? "Hide Terminal" : "Show Terminal")

                // Run button
                Button {
                    onRunCommand?()
                } label: {
                    Image(systemName: "play.fill")
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.plain)
                .help("Run Command")

                // Run settings
                Button {
                    onConfigureRunCommand?()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.plain)
                .help("Configure Run Command")

                // Open in... menu (native SwiftUI Menu)
                Menu {
                    Button {
                        IDEDetector.revealInFinder(path: chat.workingDirectory)
                    } label: {
                        Label("Reveal in Finder", systemImage: "folder")
                    }

                    Divider()

                    let apps = IDEDetector.detectInstalled()
                    ForEach(apps, id: \.bundleID) { app in
                        Button("Open in \(app.name)") {
                            IDEDetector.open(bundleID: app.bundleID, path: chat.workingDirectory)
                        }
                    }
                } label: {
                    Image(systemName: "folder")
                        .foregroundStyle(Color.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Open In...")

                if isProcessing {
                    ProgressView()
                        .controlSize(.small)

                    Button(action: onCancel) {
                        Image(systemName: "stop.circle")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Cancel generation")
                }

                Button {
                    appState.isInspectorVisible.toggle()
                } label: {
                    Image(systemName: "sidebar.trailing")
                        .foregroundStyle(appState.isInspectorVisible ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .help(appState.isInspectorVisible ? "Hide Inspector" : "Show Inspector")
            }
            .padding(.leading, appState.isSidebarVisible ? 16 : TitleBarMetrics.standard.trafficLightInset)
            .padding(.trailing, 16)
            .frame(height: 52)

            Divider().opacity(0.5)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Git Branch Badge

struct GitBranchBadge: View {
    let branchName: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "arrow.triangle.branch")
                .font(.caption2)
            Text(branchName)
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(Capsule())
    }
}
