import Foundation
import SwiftData

@Observable
final class AppState {
    var selectedProject: Project?
    var selectedChat: Chat?
    var isSidebarVisible: Bool = true
    var isInspectorVisible: Bool = false
    var isTerminalVisible: Bool = false
}
