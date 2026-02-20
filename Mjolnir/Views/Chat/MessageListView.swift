import SwiftUI
import SwiftData

struct MessageListView: View {
    let chatID: UUID
    let streamingText: String
    let streamingToolCalls: [StreamingToolCall]
    let isProcessing: Bool

    @Query private var messages: [Message]

    init(
        chatID: UUID,
        streamingText: String,
        streamingToolCalls: [StreamingToolCall],
        isProcessing: Bool
    ) {
        self.chatID = chatID
        self.streamingText = streamingText
        self.streamingToolCalls = streamingToolCalls
        self.isProcessing = isProcessing

        let id = chatID
        _messages = Query(
            filter: #Predicate<Message> { message in
                message.chat?.id == id
            },
            sort: \.createdAt
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Spacer()
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }

                    if isProcessing || !streamingText.isEmpty {
                        StreamingMessageView(
                            text: streamingText,
                            toolCalls: streamingToolCalls,
                            isProcessing: isProcessing
                        )
                        .id("streaming")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.bottom)
            .onChange(of: streamingText) { _, _ in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}
