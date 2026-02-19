import SwiftUI

struct DiffView: View {
    let filePath: String
    let diffContent: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)
                Text(filePath)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.head)
                Spacer()
                Button("Done") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    let lines = diffContent.components(separatedBy: "\n")
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        DiffLineView(line: line, lineNumber: index + 1)
                    }
                }
                .padding(12)
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
        .frame(minWidth: 500, minHeight: 400)
        .frame(idealWidth: 700, idealHeight: 500)
    }
}

struct DiffLineView: View {
    let line: String
    let lineNumber: Int

    var body: some View {
        HStack(spacing: 0) {
            Text("\(lineNumber)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 40, alignment: .trailing)
                .padding(.trailing, 8)

            Text(line)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(lineColor)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 1)
        .background(lineBackground)
    }

    private var lineColor: Color {
        if line.hasPrefix("+") && !line.hasPrefix("+++") { return .green }
        if line.hasPrefix("-") && !line.hasPrefix("---") { return .red }
        if line.hasPrefix("@@") { return .cyan }
        return .primary
    }

    private var lineBackground: Color {
        if line.hasPrefix("+") && !line.hasPrefix("+++") { return Color.green.opacity(0.1) }
        if line.hasPrefix("-") && !line.hasPrefix("---") { return Color.red.opacity(0.1) }
        if line.hasPrefix("@@") { return Color.cyan.opacity(0.05) }
        return .clear
    }
}
