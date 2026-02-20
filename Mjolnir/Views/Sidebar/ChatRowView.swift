import SwiftUI
import SwiftData

struct ChatRowView: View {
    @Bindable var chat: Chat
    let isSelected: Bool
    let onRename: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "message.fill")
                .foregroundStyle(.secondary)

            Text(chat.title)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)

            if chat.hasWorktree {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundStyle(.secondary)
            }

            if isHovered {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(ToolbarButtonStyle())
                .help("Delete Chat")
            }
        }
        .onHover { isHovered = $0 }
        .sidebarRow(isSelected: isSelected)
        .contextMenu {
            Button("Rename...") { onRename() }
            Button("Duplicate") { onDuplicate() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}
