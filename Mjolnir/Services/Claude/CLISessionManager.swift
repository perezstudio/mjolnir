import Foundation
import SwiftData

class CLISessionManager {

    func handleSessionInit(_ initMessage: CLISystemInit, chat: Chat) {
        chat.sessionID = initMessage.sessionId
        chat.updatedAt = Date()
    }

    func resumeSessionID(for chat: Chat) -> String? {
        chat.sessionID
    }

    func forkSession(from chat: Chat, in project: Project, modelContext: ModelContext) -> Chat {
        let newChat = Chat(title: "\(chat.title) (fork)", project: project)
        newChat.hasWorktree = false
        newChat.sortOrder = (project.chats.count)
        modelContext.insert(newChat)

        // Copy messages from the source chat
        let sortedMessages = chat.messages.sorted { $0.createdAt < $1.createdAt }
        for sourceMessage in sortedMessages {
            let copy = Message(role: sourceMessage.role, content: sourceMessage.content, chat: newChat)
            copy.createdAt = sourceMessage.createdAt
            copy.inputTokens = sourceMessage.inputTokens
            copy.outputTokens = sourceMessage.outputTokens
            copy.modelID = sourceMessage.modelID
            copy.stopReason = sourceMessage.stopReason
            modelContext.insert(copy)
        }

        return newChat
    }
}
