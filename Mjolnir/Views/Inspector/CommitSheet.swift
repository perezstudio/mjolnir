import SwiftUI

struct CommitSheet: View {
    let files: [GitFileStatus]
    @Binding var selectedFiles: Set<String>
    @Binding var commitMessage: String
    let onCommit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Commit Changes")
                .font(.headline)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(files) { file in
                        Toggle(isOn: fileBinding(for: file.path)) {
                            HStack(spacing: 6) {
                                Text(file.displayStatus.label)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(statusColor(for: file))
                                Text(file.path)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                    .truncationMode(.head)
                            }
                        }
                        .toggleStyle(.checkbox)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: 200)

            VStack(alignment: .leading, spacing: 4) {
                Text("Commit message")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Describe your changes...", text: $commitMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }

            HStack {
                Button("Cancel", role: .cancel) { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Commit \(selectedFiles.count) file(s)") { onCommit() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(
                        selectedFiles.isEmpty
                            || commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
            }
        }
        .padding(20)
        .frame(width: 450)
    }

    private func fileBinding(for path: String) -> Binding<Bool> {
        Binding(
            get: { selectedFiles.contains(path) },
            set: { isSelected in
                if isSelected { selectedFiles.insert(path) }
                else { selectedFiles.remove(path) }
            }
        )
    }

    private func statusColor(for file: GitFileStatus) -> Color {
        switch file.displayStatus {
        case .added: return .green
        case .modified: return .yellow
        case .deleted: return .red
        case .untracked: return .gray
        case .renamed: return .blue
        }
    }
}
