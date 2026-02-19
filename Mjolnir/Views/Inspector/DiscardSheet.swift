import SwiftUI

struct DiscardSheet: View {
    let files: [GitFileStatus]
    @Binding var selectedFiles: Set<String>
    let onDiscard: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.yellow)

            Text("Discard Changes")
                .font(.headline)

            Text("This will permanently discard changes to the selected files. This cannot be undone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(files) { file in
                        Toggle(isOn: fileBinding(for: file.path)) {
                            HStack(spacing: 6) {
                                Text(file.displayStatus.label)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
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

            HStack {
                Button("Cancel", role: .cancel) { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Discard \(selectedFiles.count) file(s)", role: .destructive) { onDiscard() }
                    .disabled(selectedFiles.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
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
}
