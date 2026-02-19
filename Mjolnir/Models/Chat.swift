import Foundation
import SwiftData

@Model
final class Chat {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Int
    var isActive: Bool
    var sessionID: String?
    var branchName: String?
    var worktreePath: String?
    var baseBranch: String?
    var hasWorktree: Bool

    var project: Project?

    @Relationship(deleteRule: .cascade, inverse: \Message.chat)
    var messages: [Message]

    var workingDirectory: String {
        worktreePath ?? project?.path ?? ""
    }

    init(title: String, project: Project) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sortOrder = 0
        self.isActive = false
        self.hasWorktree = false
        self.messages = []
        self.project = project
    }
}
