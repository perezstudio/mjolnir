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
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "folder")
                    .font(.system(size: 28))
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
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                        .frame(width: 12)
                } else {
                    Spacer().frame(width: 12)
                }

                Image(systemName: node.isDirectory
                    ? (isExpanded ? "folder.fill" : "folder")
                    : fileIcon(for: node.name))
                    .font(.system(size: 12))
                    .foregroundStyle(node.isDirectory ? .secondary : .tertiary)

                Text(node.name)
                    .font(.system(size: 12))
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

    private func fileIcon(for name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "js", "ts", "jsx", "tsx": return "curlybraces"
        case "json": return "curlybraces.square"
        case "md", "txt", "rtf": return "doc.text"
        case "png", "jpg", "jpeg", "gif", "svg": return "photo"
        case "py": return "chevron.left.forwardslash.chevron.right"
        case "html", "css": return "globe"
        case "yml", "yaml", "toml": return "gearshape"
        case "sh", "zsh", "bash": return "terminal"
        default: return "doc"
        }
    }
}
