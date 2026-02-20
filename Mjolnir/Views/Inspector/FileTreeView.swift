import SwiftUI

struct FileTreeView: View {
    let rootNode: FileNode?
    let isLoading: Bool

    var body: some View {
        if isLoading && rootNode == nil {
            ProgressView("Loading...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let root = rootNode, let children = root.children {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(children) { child in
                        FileNodeRow(node: child, depth: 0)
                    }
                }
                .padding(8)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "folder")
                    .imageScale(.large)
                    .foregroundStyle(.tertiary)
                Text("No project selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct FileNodeRow: View {
    let node: FileNode
    let depth: Int
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                if node.isDirectory {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundStyle(.tertiary)
                        .frame(width: 12)
                } else {
                    Spacer().frame(width: 12)
                }

                let iconInfo =
                    node.isDirectory
                    ? (isExpanded ? ("folder.fill", Color.secondary) : ("folder", Color.secondary))
                    : fileIconAndColor(for: node.name)

                Image(systemName: iconInfo.0)
                    .foregroundStyle(iconInfo.1)

                Text(node.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.leading, CGFloat(depth) * 16)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if node.isDirectory {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                }
            }

            if isExpanded, let children = node.children {
                ForEach(children) { child in
                    FileNodeRow(node: child, depth: depth + 1)
                }
            }
        }
    }

    private func fileIconAndColor(for name: String) -> (String, Color) {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return ("swift", .orange)
        case "ts": return ("curlybraces", .blue)
        case "tsx": return ("curlybraces", .blue)
        case "js": return ("curlybraces", .yellow)
        case "jsx": return ("curlybraces", .cyan)
        case "json": return ("curlybraces.square", .yellow)
        case "md", "txt", "rtf": return ("doc.text", .teal)
        case "png", "jpg", "jpeg", "gif": return ("photo", .purple)
        case "svg": return ("photo", .orange)
        case "py": return ("chevron.left.forwardslash.chevron.right", .blue)
        case "rb": return ("chevron.left.forwardslash.chevron.right", .red)
        case "html": return ("globe", .orange)
        case "css", "scss", "less": return ("paintbrush", .blue)
        case "yml", "yaml", "toml": return ("gearshape", .gray)
        case "sh", "zsh", "bash": return ("terminal", .green)
        case "go": return ("chevron.left.forwardslash.chevron.right", .cyan)
        case "rs": return ("chevron.left.forwardslash.chevron.right", .orange)
        case "c", "h": return ("chevron.left.forwardslash.chevron.right", .blue)
        case "cpp", "hpp", "cc": return ("chevron.left.forwardslash.chevron.right", .blue)
        case "java", "kt": return ("cup.and.saucer", .orange)
        case "entitlements", "plist": return ("gearshape", .gray)
        case "xcodeproj", "xcworkspace": return ("hammer", .blue)
        default: return ("doc", .secondary)
        }
    }
}
