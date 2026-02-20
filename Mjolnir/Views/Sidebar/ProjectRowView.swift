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
            Image(systemName: project.isExpanded ? "text.below.folder.fill" : "folder.fill")
                .foregroundStyle(.blue)
                .contentTransition(.symbolEffect(.replace))

            Text(project.name)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Text("\(project.chats.count)")
                .foregroundStyle(.tertiary)
                .monospacedDigit()

            Button {
                onNewChat()
            } label: {
                Image(systemName: "plus")
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(ToolbarButtonStyle())
            .help("New Chat")
        }
        .sidebarRow()
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                project.isExpanded.toggle()
            }
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
