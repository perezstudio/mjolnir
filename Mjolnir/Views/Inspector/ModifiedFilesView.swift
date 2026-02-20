import SwiftUI

struct ModifiedFilesView: View {
    let files: [GitFileStatus]
    let isLoading: Bool
    let onSelectFile: (GitFileStatus) -> Void

    var body: some View {
        if isLoading && files.isEmpty {
            ProgressView("Checking status...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if files.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .imageScale(.large)
                    .foregroundStyle(.green)
                Text("Working tree clean")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(files) { file in
                        ModifiedFileRow(file: file)
                            .onTapGesture { onSelectFile(file) }
                    }
                }
                .padding(8)
            }
        }
    }
}

struct ModifiedFileRow: View {
    let file: GitFileStatus

    var body: some View {
        HStack(spacing: 8) {
            Text(file.displayStatus.label)
                .font(.body.monospaced().bold())
                .foregroundStyle(statusColor)
                .frame(width: 16)

            Text((file.path as NSString).lastPathComponent)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var statusColor: Color {
        switch file.displayStatus {
        case .added: return .green
        case .modified: return .yellow
        case .deleted: return .red
        case .renamed: return .blue
        }
    }
}
