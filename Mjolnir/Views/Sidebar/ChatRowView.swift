import SwiftUI
import SwiftData

struct ChatRowView: View {
    @Bindable var chat: Chat
    let isSelected: Bool
    let onRename: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bubble.left")
                .foregroundStyle(isSelected ? .white : .secondary)

            Text(chat.title)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(isSelected ? .white : .primary)

            Spacer()

            if chat.hasWorktree {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundStyle(isSelected ? Color.white.opacity(0.7) : Color.secondary)


            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contextMenu {
            Button("Rename...") { onRename() }
            Button("Duplicate") { onDuplicate() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}
