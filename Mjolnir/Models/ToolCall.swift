import Foundation
import SwiftData

@Model
final class ToolCall {
    var id: UUID
    var toolUseID: String
    var toolName: String
    var inputJSON: String
    var outputJSON: String?
    var status: String

    var message: Message?

    init(toolUseID: String, toolName: String, inputJSON: String, message: Message) {
        self.id = UUID()
        self.toolUseID = toolUseID
        self.toolName = toolName
        self.inputJSON = inputJSON
        self.status = "pending"
        self.message = message
    }
}
