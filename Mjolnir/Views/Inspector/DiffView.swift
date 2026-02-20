import SwiftUI
import AppKit

// MARK: - Diff Window Opener

final class DiffWindowController: NSWindowController, NSWindowDelegate {
    private static var openWindows: [DiffWindowController] = []

    static func open(filePath: String, oldContent: String, newContent: String) {
        let diffView = DiffView(
            filePath: filePath,
            oldContent: oldContent,
            newContent: newContent
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = (filePath as NSString).lastPathComponent
        window.subtitle = filePath
        window.contentView = NSHostingView(rootView: diffView)
        window.center()
        window.isReleasedWhenClosed = false

        let controller = DiffWindowController(window: window)
        window.delegate = controller
        openWindows.append(controller)
        controller.showWindow(nil)
    }

    func windowWillClose(_ notification: Notification) {
        DiffWindowController.openWindows.removeAll { $0 === self }
    }
}

// MARK: - Side-by-Side Diff View

struct DiffView: View {
    let filePath: String
    let oldContent: String
    let newContent: String

    private var fileExtension: String {
        (filePath as NSString).pathExtension
    }

    private var diffResult: DiffResult {
        computeDiff(old: oldContent, new: newContent)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                Text("HEAD")
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.05))

                Divider().frame(height: 30)

                Text("Working Copy")
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.05))
            }

            Divider()

            // Side-by-side content
            GeometryReader { geometry in
                let halfWidth = geometry.size.width / 2

                ScrollView([.vertical]) {
                    HStack(alignment: .top, spacing: 0) {
                        // Left pane: old content
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(diffResult.lines.enumerated()), id: \.offset) { _, line in
                                DiffLinePaneView(
                                    lineNumber: line.oldLineNumber,
                                    text: line.oldText,
                                    type: line.type,
                                    side: .old,
                                    fileExtension: fileExtension
                                )
                            }
                        }
                        .frame(width: halfWidth)

                        Divider()

                        // Right pane: new content
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(diffResult.lines.enumerated()), id: \.offset) { _, line in
                                DiffLinePaneView(
                                    lineNumber: line.newLineNumber,
                                    text: line.newText,
                                    type: line.type,
                                    side: .new,
                                    fileExtension: fileExtension
                                )
                            }
                        }
                        .frame(width: halfWidth)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .frame(minWidth: 600, minHeight: 400)
    }
}

// MARK: - Diff Line Pane View

enum DiffSide {
    case old, new
}

struct DiffLinePaneView: View {
    let lineNumber: Int?
    let text: String?
    let type: DiffLineType
    let side: DiffSide
    let fileExtension: String

    var body: some View {
        HStack(spacing: 0) {
            // Line number
            Text(lineNumber.map { "\($0)" } ?? "")
                .monospaced()
                .foregroundStyle(.tertiary)
                .frame(width: 40, alignment: .trailing)
                .padding(.trailing, 8)

            // Content with syntax highlighting
            if let text {
                Text(SyntaxHighlighter.highlight(text, fileExtension: fileExtension))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("")
                    .monospaced()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 1)
        .padding(.trailing, 4)
        .background(backgroundColor)
    }

    private var backgroundColor: Color {
        switch type {
        case .unchanged, .separator:
            return .clear
        case .added:
            return side == .new ? Color.green.opacity(0.12) : .clear
        case .removed:
            return side == .old ? Color.red.opacity(0.12) : .clear
        case .modified:
            return side == .old ? Color.red.opacity(0.08) : Color.green.opacity(0.08)
        }
    }
}

// MARK: - Diff Computation

enum DiffLineType {
    case unchanged
    case added
    case removed
    case modified
    case separator
}

struct DiffLine {
    let oldLineNumber: Int?
    let newLineNumber: Int?
    let oldText: String?
    let newText: String?
    let type: DiffLineType
}

struct DiffResult {
    let lines: [DiffLine]
}

private func computeDiff(old: String, new: String) -> DiffResult {
    let oldLines = old.isEmpty ? [] : old.components(separatedBy: "\n")
    let newLines = new.isEmpty ? [] : new.components(separatedBy: "\n")

    // Use LCS-based diff
    let table = lcsTable(oldLines, newLines)
    var result: [DiffLine] = []
    buildDiff(table: table, oldLines: oldLines, newLines: newLines,
              i: oldLines.count, j: newLines.count, result: &result)

    return DiffResult(lines: result)
}

private func lcsTable(_ old: [String], _ new: [String]) -> [[Int]] {
    let m = old.count
    let n = new.count
    var table = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

    for i in 1...max(m, 1) {
        guard i <= m else { break }
        for j in 1...max(n, 1) {
            guard j <= n else { break }
            if old[i - 1] == new[j - 1] {
                table[i][j] = table[i - 1][j - 1] + 1
            } else {
                table[i][j] = max(table[i - 1][j], table[i][j - 1])
            }
        }
    }

    return table
}

private func buildDiff(table: [[Int]], oldLines: [String], newLines: [String],
                        i: Int, j: Int, result: inout [DiffLine]) {
    if i > 0 && j > 0 && oldLines[i - 1] == newLines[j - 1] {
        buildDiff(table: table, oldLines: oldLines, newLines: newLines,
                  i: i - 1, j: j - 1, result: &result)
        result.append(DiffLine(
            oldLineNumber: i, newLineNumber: j,
            oldText: oldLines[i - 1], newText: newLines[j - 1],
            type: .unchanged
        ))
    } else if j > 0 && (i == 0 || table[i][j - 1] >= table[i - 1][j]) {
        buildDiff(table: table, oldLines: oldLines, newLines: newLines,
                  i: i, j: j - 1, result: &result)
        result.append(DiffLine(
            oldLineNumber: nil, newLineNumber: j,
            oldText: nil, newText: newLines[j - 1],
            type: .added
        ))
    } else if i > 0 && (j == 0 || table[i][j - 1] < table[i - 1][j]) {
        buildDiff(table: table, oldLines: oldLines, newLines: newLines,
                  i: i - 1, j: j, result: &result)
        result.append(DiffLine(
            oldLineNumber: i, newLineNumber: nil,
            oldText: oldLines[i - 1], newText: nil,
            type: .removed
        ))
    }
}
