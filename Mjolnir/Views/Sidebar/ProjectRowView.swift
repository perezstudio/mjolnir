import SwiftUI
import SwiftData

struct ProjectRowView: View {
    @Bindable var project: Project
    let onNewChat: () -> Void
    let onNewWorktreeChat: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.secondary)
                .font(.system(size: 13))

            Text(project.name)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Text("\(project.chats.count)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
        .contextMenu {
            Button("New Chat") { onNewChat() }
            Button("New Worktree Chat") { onNewWorktreeChat() }
            Divider()
            Button("Rename...") { onRename() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}
