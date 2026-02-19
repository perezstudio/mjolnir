import SwiftUI

struct ChatHeaderView: View {
    @Bindable var chat: Chat
    @Bindable var appState: AppState
    let isProcessing: Bool
    let onCancel: () -> Void

    @State private var isEditingTitle = false
    @State private var editedTitle = ""

    var body: some View {
        HStack(spacing: 12) {
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

            // Show toggle only when inspector is hidden
            if !appState.isInspectorVisible {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.isInspectorVisible = true
                    }
                } label: {
                    Image(systemName: "sidebar.trailing")
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.plain)
                .help("Show Inspector")
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .animation(.easeInOut(duration: 0.2), value: appState.isInspectorVisible)
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
