import SwiftUI

struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack(alignment: .top) {
            if message.role == "user" {
                Spacer(minLength: 60)
                userBubble
            } else {
                assistantBubble
                Spacer(minLength: 60)
            }
        }
    }

    private var userBubble: some View {
        Text(message.content)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .textSelection(.enabled)
    }

    private var assistantBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            MarkdownTextView(content: message.content)

            let sortedToolCalls = message.toolCalls.sorted { $0.toolName < $1.toolName }
            ForEach(sortedToolCalls) { toolCall in
                ToolCallView(toolCall: toolCall)
            }

            if message.outputTokens > 0 {
                HStack(spacing: 4) {
                    if let model = message.modelID {
                        Text(modelDisplayName(model))
                    }
                    Text("\(message.outputTokens) tokens")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .textSelection(.enabled)
    }

    private func modelDisplayName(_ id: String) -> String {
        if id.contains("sonnet") { return "Sonnet" }
        if id.contains("opus") { return "Opus" }
        if id.contains("haiku") { return "Haiku" }
        return id
    }
}

// MARK: - Streaming Message View

struct StreamingMessageView: View {
    let text: String
    let toolCalls: [StreamingToolCall]
    let isProcessing: Bool

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                if !text.isEmpty {
                    MarkdownTextView(content: text)
                }

                ForEach(toolCalls) { tc in
                    StreamingToolCallView(toolCall: tc)
                }

                if isProcessing && text.isEmpty && toolCalls.isEmpty {
                    TypingIndicatorView()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer(minLength: 60)
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicatorView: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .opacity(animating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}
