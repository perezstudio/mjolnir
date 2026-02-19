import Foundation

// MARK: - File Node

struct FileNode: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    let isDirectory: Bool
    var children: [FileNode]?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - File System Service

actor FileSystemService {

    private let ignoredNames: Set<String> = [
        ".git", ".mjolnir", "node_modules", ".build", "DerivedData",
        ".svn", ".hg", "__pycache__", ".DS_Store", ".Trash",
    ]

    func buildFileTree(at path: String, maxDepth: Int = 5) throws -> FileNode {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw FileSystemError.pathNotFound(path)
        }
        return try buildNode(at: url, depth: 0, maxDepth: maxDepth)
    }

    private func buildNode(at url: URL, depth: Int, maxDepth: Int) throws -> FileNode {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        fm.fileExists(atPath: url.path, isDirectory: &isDir)

        if isDir.boolValue {
            var children: [FileNode]? = nil
            if depth < maxDepth {
                let contents = try fm.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )
                children = try contents
                    .filter { !ignoredNames.contains($0.lastPathComponent) }
                    .sorted { lhs, rhs in
                        let lhsIsDir = (try? lhs.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                        let rhsIsDir = (try? rhs.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                        if lhsIsDir != rhsIsDir { return lhsIsDir }
                        return lhs.lastPathComponent.localizedCaseInsensitiveCompare(rhs.lastPathComponent) == .orderedAscending
                    }
                    .map { try buildNode(at: $0, depth: depth + 1, maxDepth: maxDepth) }
            }
            return FileNode(id: url.path, name: url.lastPathComponent, path: url.path, isDirectory: true, children: children)
        } else {
            return FileNode(id: url.path, name: url.lastPathComponent, path: url.path, isDirectory: false, children: nil)
        }
    }
}

enum FileSystemError: LocalizedError {
    case pathNotFound(String)

    var errorDescription: String? {
        switch self {
        case .pathNotFound(let path):
            return "Path not found: \(path)"
        }
    }
}
