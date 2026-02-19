import SwiftUI

struct TerminalAreaView: View {
    @Bindable var manager: TerminalManager
    let workingDirectory: String

    var body: some View {
        HStack(spacing: 0) {
            // Left: terminal session list
            sessionList
                .frame(width: manager.sidebarWidth)
                .background(Color(nsColor: .controlBackgroundColor))

            // Horizontal resize handle
            ResizeHandle(axis: .horizontal)
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            let newWidth = manager.sidebarWidth + value.translation.width
                            manager.sidebarWidth = max(80, min(300, newWidth))
                        }
                )

            // Right: active terminal
            if !manager.sessions.isEmpty {
                MultiTerminalView(
                    sessions: manager.sessions,
                    activeSessionID: manager.activeSessionID,
                    theme: manager.theme
                )
            } else {
                emptyState
            }
        }
    }

    // MARK: - Session List

    private var sessionList: some View {
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
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No terminals open")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("New Terminal") {
                manager.addSession(workingDirectory: workingDirectory)
            }
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Resize Handle

struct ResizeHandle: View {
    enum Axis { case horizontal, vertical }
    let axis: Axis

    @State private var isHovered = false

    var body: some View {
        Group {
            switch axis {
            case .horizontal:
                Rectangle()
                    .fill(isHovered ? Color.accentColor.opacity(0.5) : Color(nsColor: .separatorColor))
                    .frame(width: 4)
                    .frame(maxHeight: .infinity)
                    .onHover { hovering in
                        isHovered = hovering
                        if hovering {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
            case .vertical:
                Rectangle()
                    .fill(isHovered ? Color.accentColor.opacity(0.5) : Color(nsColor: .separatorColor))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
                    .onHover { hovering in
                        isHovered = hovering
                        if hovering {
                            NSCursor.resizeUpDown.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
            }
        }
        .contentShape(Rectangle())
    }
}
