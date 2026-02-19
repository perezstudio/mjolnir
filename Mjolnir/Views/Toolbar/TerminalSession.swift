import Foundation

@Observable
class TerminalSession: Identifiable {
    let id = UUID()
    var title: String
    let workingDirectory: String
    var pendingCommand: String?

    init(title: String, workingDirectory: String, command: String? = nil) {
        self.title = title
        self.workingDirectory = workingDirectory
        self.pendingCommand = command
    }
}

@Observable
class TerminalManager {
    var sessions: [TerminalSession] = []
    var activeSessionID: UUID?

    var activeSession: TerminalSession? {
        sessions.first { $0.id == activeSessionID }
    }

    func addSession(workingDirectory: String, title: String? = nil, command: String? = nil) {
        let session = TerminalSession(
            title: title ?? "Terminal \(sessions.count + 1)",
            workingDirectory: workingDirectory,
            command: command
        )
        sessions.append(session)
        activeSessionID = session.id
    }

    func removeSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        if activeSessionID == id {
            activeSessionID = sessions.last?.id
        }
    }

    func reset() {
        sessions.removeAll()
        activeSessionID = nil
    }
}
