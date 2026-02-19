import Foundation
import AppKit

// MARK: - Terminal Theme

enum TerminalTheme: String, CaseIterable {
    case dark
    case light

    var foregroundColor: NSColor {
        switch self {
        case .dark: .init(white: 0.9, alpha: 1)
        case .light: .init(white: 0.1, alpha: 1)
        }
    }

    var backgroundColor: NSColor {
        switch self {
        case .dark: .init(red: 0.118, green: 0.118, blue: 0.118, alpha: 1) // #1e1e1e
        case .light: .white
        }
    }

    var caretColor: NSColor {
        switch self {
        case .dark: .init(white: 0.85, alpha: 1)
        case .light: .init(white: 0.2, alpha: 1)
        }
    }
}

// MARK: - Terminal Session

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

// MARK: - Terminal Manager

@Observable
class TerminalManager {
    var sessions: [TerminalSession] = []
    var activeSessionID: UUID?
    var theme: TerminalTheme = .dark
    var sidebarWidth: CGFloat = 140

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
