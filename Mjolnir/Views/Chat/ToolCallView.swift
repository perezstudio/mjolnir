import SwiftUI

struct ToolCallView: View {
    let toolCall: ToolCall
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Input")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(toolCall.inputJSON)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                if let output = toolCall.outputJSON {
                    Text("Output")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(output)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .lineLimit(20)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(.top, 4)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: toolIconName(toolCall.toolName))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(toolCall.toolName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                statusBadge(toolCall.status)
            }
        }
    }

    private func toolIconName(_ name: String) -> String {
        switch name {
        case "Read": return "doc.text"
        case "Write": return "square.and.pencil"
        case "Edit": return "pencil.line"
        case "Bash": return "terminal"
        case "Glob": return "magnifyingglass"
        case "Grep": return "text.magnifyingglass"
        case "WebSearch", "WebFetch": return "globe"
        case "Task": return "arrow.triangle.branch"
        default: return "wrench"
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: String) -> some View {
        switch status {
        case "completed":
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        case "error":
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.caption)
        default:
            ProgressView()
                .controlSize(.mini)
        }
    }
}

// MARK: - Streaming Tool Call View

struct StreamingToolCallView: View {
    let toolCall: StreamingToolCall

    var body: some View {
        HStack(spacing: 6) {
            if !toolCall.isComplete {
                ProgressView()
                    .controlSize(.mini)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
            Image(systemName: "wrench")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(toolCall.name)
                .font(.caption)
                .foregroundStyle(.secondary)
            if toolCall.elapsedSeconds > 0 {
                Text(String(format: "%.1fs", toolCall.elapsedSeconds))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
