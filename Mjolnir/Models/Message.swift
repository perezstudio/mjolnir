import Foundation
import SwiftData

@Model
final class Message {
    var id: UUID
    var role: String
    var content: String
    var createdAt: Date
    var isStreaming: Bool
    var stopReason: String?
    var inputTokens: Int
    var outputTokens: Int
    var modelID: String?

    var chat: Chat?

    @Relationship(deleteRule: .cascade, inverse: \ToolCall.message)
    var toolCalls: [ToolCall]

    init(role: String, content: String, chat: Chat) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.createdAt = Date()
        self.isStreaming = false
        self.inputTokens = 0
        self.outputTokens = 0
        self.toolCalls = []
        self.chat = chat
    }
}
