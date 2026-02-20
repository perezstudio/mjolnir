import Foundation
import CoreServices

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

// MARK: - File System Watcher

final class FileSystemWatcher: Sendable {
    private let stream: FSEventStreamRef
    private let queue: DispatchQueue

    init(path: String, debounceSeconds: Double, onChange: @escaping @Sendable () -> Void) {
        let queue = DispatchQueue(label: "com.mjolnir.fswatcher", qos: .utility)
        self.queue = queue

        let box = CallbackBox(action: onChange, debounce: debounceSeconds)
        let context = UnsafeMutableRawPointer(Unmanaged.passRetained(box).toOpaque())

        var fsContext = FSEventStreamContext(
            version: 0,
            info: context,
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        self.stream = FSEventStreamCreate(
            nil,
            fsEventsCallback,
            &fsContext,
            [path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        )!

        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    func stop() {
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
    }
}

private final class CallbackBox: @unchecked Sendable {
    let action: @Sendable () -> Void
    let debounce: Double
    private let debounceQueue = DispatchQueue(label: "com.mjolnir.fswatcher.debounce")
    private var debounceWork: DispatchWorkItem?

    init(action: @escaping @Sendable () -> Void, debounce: Double) {
        self.action = action
        self.debounce = debounce
    }

    func scheduleAction() {
        debounceQueue.async { [self] in
            debounceWork?.cancel()
            let work = DispatchWorkItem { [self] in action() }
            debounceWork = work
            debounceQueue.asyncAfter(deadline: .now() + debounce, execute: work)
        }
    }
}

private func fsEventsCallback(
    _ streamRef: ConstFSEventStreamRef,
    _ clientCallBackInfo: UnsafeMutableRawPointer?,
    _ numEvents: Int,
    _ eventPaths: UnsafeMutableRawPointer,
    _ eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    _ eventIds: UnsafePointer<FSEventStreamEventId>
) {
    guard let info = clientCallBackInfo else { return }
    let box = Unmanaged<CallbackBox>.fromOpaque(info).takeUnretainedValue()
    box.scheduleAction()
}

// MARK: - File System Service

actor FileSystemService {

    private var watcher: FileSystemWatcher?

    private let ignoredNames: Set<String> = [
        ".git", ".mjolnir", "node_modules", ".build", "DerivedData",
        ".svn", ".hg", "__pycache__", ".DS_Store", ".Trash",
    ]

    func startWatching(path: String, onChange: @escaping @Sendable () -> Void) {
        stopWatching()
        watcher = FileSystemWatcher(path: path, debounceSeconds: 0.5, onChange: onChange)
    }

    func stopWatching() {
        watcher?.stop()
        watcher = nil
    }

    func buildFileTree(at path: String, maxDepth: Int = 3) throws -> FileNode {
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
