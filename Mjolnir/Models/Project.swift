import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var path: String
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Int
    var isExpanded: Bool
    var runCommand: String?
    var systemPrompt: String?

    @Relationship(deleteRule: .cascade, inverse: \Chat.project)
    var chats: [Chat]

    init(name: String, path: String) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sortOrder = 0
        self.isExpanded = true
        self.chats = []
    }
}
