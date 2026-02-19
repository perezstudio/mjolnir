import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID
    var defaultModel: String
    var theme: String
    var maxTokens: Int

    init() {
        self.id = UUID()
        self.defaultModel = "claude-sonnet-4-20250514"
        self.theme = "system"
        self.maxTokens = 8192
    }
}
