import SwiftUI

struct MarkdownTextView: View {
    let content: String

    var body: some View {
        let segments = parseSegments(content)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .markdown(let text):
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(attributedMarkdown(text))
                            .textSelection(.enabled)
                    }
                case .codeBlock(let language, let code):
                    CodeBlockView(language: language, code: code)
                }
            }
        }
    }

    private func attributedMarkdown(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        ))) ?? AttributedString(text)
    }

    // MARK: - Parsing

    private enum Segment {
        case markdown(String)
        case codeBlock(language: String?, code: String)
    }

    private func parseSegments(_ text: String) -> [Segment] {
        var segments: [Segment] = []
        var currentMarkdown = ""
        let lines = text.components(separatedBy: "\n")
        var inCodeBlock = false
        var codeLanguage: String?
        var codeLines: [String] = []

        for line in lines {
            if !inCodeBlock && line.hasPrefix("```") {
                // Start code block
                if !currentMarkdown.isEmpty {
                    segments.append(.markdown(currentMarkdown))
                    currentMarkdown = ""
                }
                inCodeBlock = true
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                codeLanguage = lang.isEmpty ? nil : lang
                codeLines = []
            } else if inCodeBlock && line.hasPrefix("```") {
                // End code block
                segments.append(.codeBlock(language: codeLanguage, code: codeLines.joined(separator: "\n")))
                inCodeBlock = false
                codeLanguage = nil
                codeLines = []
            } else if inCodeBlock {
                codeLines.append(line)
            } else {
                if !currentMarkdown.isEmpty {
                    currentMarkdown += "\n"
                }
                currentMarkdown += line
            }
        }

        // Handle unclosed code block or remaining markdown
        if inCodeBlock {
            segments.append(.codeBlock(language: codeLanguage, code: codeLines.joined(separator: "\n")))
        } else if !currentMarkdown.isEmpty {
            segments.append(.markdown(currentMarkdown))
        }

        return segments
    }
}

// MARK: - Code Block View

struct CodeBlockView: View {
    let language: String?
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language, !language.isEmpty {
                HStack {
                    Text(language)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(code, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)
                .padding(.bottom, 4)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(.horizontal, 10)
                    .padding(.vertical, language != nil ? 4 : 10)
            }
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}
