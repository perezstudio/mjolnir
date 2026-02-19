import SwiftUI

struct SyntaxHighlighter {

    static func highlight(_ text: String, fileExtension ext: String) -> AttributedString {
        let rules = rules(for: ext)
        guard !rules.isEmpty else {
            return AttributedString(text)
        }

        var result = AttributedString(text)
        result.font = .system(size: 12, design: .monospaced)

        // Apply comment/string rules first (they take priority), then keywords/types/numbers
        for rule in rules {
            applyRule(rule, to: &result, in: text)
        }

        return result
    }

    // MARK: - Rule Application

    private static func applyRule(_ rule: HighlightRule, to attributed: inout AttributedString, in text: String) {
        guard let regex = try? NSRegularExpression(pattern: rule.pattern, options: rule.options) else { return }
        let nsRange = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: nsRange)

        for match in matches {
            guard let range = Range(match.range, in: text),
                  let attrRange = Range(range, in: attributed) else { continue }
            attributed[attrRange].foregroundColor = rule.color
            if rule.italic {
                attributed[attrRange].font = .system(size: 12, design: .monospaced).italic()
            }
        }
    }

    // MARK: - Language Rules

    private static func rules(for ext: String) -> [HighlightRule] {
        switch ext.lowercased() {
        case "swift":
            return swiftRules
        case "js", "jsx", "ts", "tsx":
            return jsRules
        case "py":
            return pythonRules
        case "rb":
            return rubyRules
        case "go":
            return goRules
        case "rs":
            return rustRules
        case "java", "kt", "kts":
            return javaRules
        case "c", "h", "cpp", "hpp", "cc", "m", "mm":
            return cRules
        case "css", "scss", "less":
            return cssRules
        case "html", "xml", "svg":
            return htmlRules
        case "json":
            return jsonRules
        case "yaml", "yml":
            return yamlRules
        case "sh", "bash", "zsh":
            return shellRules
        case "sql":
            return sqlRules
        default:
            return genericRules
        }
    }
}

// MARK: - Highlight Rule

private struct HighlightRule {
    let pattern: String
    let color: Color
    let options: NSRegularExpression.Options
    let italic: Bool

    init(_ pattern: String, _ color: Color, options: NSRegularExpression.Options = [], italic: Bool = false) {
        self.pattern = pattern
        self.color = color
        self.options = options
        self.italic = italic
    }
}

// MARK: - Common Patterns

private let stringColor = Color(.systemRed)
private let commentColor = Color(.systemGray)
private let keywordColor = Color(.systemPink)
private let typeColor = Color(.systemCyan)
private let numberColor = Color(.systemBlue)
private let funcColor = Color(.systemPurple)
private let attrColor = Color(.systemOrange)

private let doubleQuoteString = HighlightRule(#""(?:[^"\\]|\\.)*""#, stringColor)
private let singleQuoteString = HighlightRule(#"'(?:[^'\\]|\\.)*'"#, stringColor)
private let backtickString = HighlightRule(#"`(?:[^`\\]|\\.)*`"#, stringColor)
private let lineComment = HighlightRule(#"//.*$"#, commentColor, options: .anchorsMatchLines, italic: true)
private let hashComment = HighlightRule(#"#.*$"#, commentColor, options: .anchorsMatchLines, italic: true)
private let blockComment = HighlightRule(#"/\*[\s\S]*?\*/"#, commentColor, italic: true)
private let numberLiteral = HighlightRule(#"\b\d+\.?\d*([eE][+-]?\d+)?\b"#, numberColor)

// MARK: - Language-Specific Rules

private func keywordRule(_ keywords: [String]) -> HighlightRule {
    let joined = keywords.joined(separator: "|")
    return HighlightRule(#"\b(?:"# + joined + #")\b"#, keywordColor)
}

private let swiftRules: [HighlightRule] = [
    keywordRule(["import", "class", "struct", "enum", "protocol", "extension", "func", "var", "let",
                 "if", "else", "guard", "switch", "case", "default", "for", "while", "repeat",
                 "return", "throw", "throws", "try", "catch", "do", "break", "continue", "fallthrough",
                 "self", "Self", "super", "init", "deinit", "nil", "true", "false",
                 "public", "private", "internal", "fileprivate", "open", "static", "final",
                 "override", "mutating", "nonmutating", "async", "await", "actor",
                 "where", "in", "as", "is", "some", "any", "typealias", "associatedtype",
                 "weak", "unowned", "lazy", "optional", "required", "convenience"]),
    HighlightRule(#"@\w+"#, attrColor),
    HighlightRule(#"\b[A-Z]\w*\b"#, typeColor),
    numberLiteral,
    doubleQuoteString,
    lineComment,
    blockComment,
]

private let jsRules: [HighlightRule] = [
    keywordRule(["import", "export", "from", "default", "const", "let", "var", "function",
                 "class", "extends", "return", "if", "else", "for", "while", "do",
                 "switch", "case", "break", "continue", "new", "this", "super",
                 "try", "catch", "finally", "throw", "typeof", "instanceof",
                 "async", "await", "yield", "of", "in", "true", "false", "null", "undefined",
                 "interface", "type", "enum", "implements", "readonly", "as"]),
    HighlightRule(#"\b[A-Z]\w*\b"#, typeColor),
    numberLiteral,
    doubleQuoteString,
    singleQuoteString,
    backtickString,
    lineComment,
    blockComment,
]

private let pythonRules: [HighlightRule] = [
    keywordRule(["import", "from", "as", "def", "class", "return", "if", "elif", "else",
                 "for", "while", "break", "continue", "pass", "try", "except", "finally",
                 "raise", "with", "yield", "lambda", "and", "or", "not", "in", "is",
                 "True", "False", "None", "self", "async", "await", "global", "nonlocal"]),
    HighlightRule(#"@\w+"#, attrColor),
    HighlightRule(#"\b[A-Z]\w*\b"#, typeColor),
    numberLiteral,
    HighlightRule(#"\"\"\"[\s\S]*?\"\"\""#, stringColor),
    HighlightRule(#"'''[\s\S]*?'''"#, stringColor),
    doubleQuoteString,
    singleQuoteString,
    hashComment,
]

private let rubyRules: [HighlightRule] = [
    keywordRule(["def", "end", "class", "module", "if", "elsif", "else", "unless",
                 "while", "until", "for", "do", "begin", "rescue", "ensure", "raise",
                 "return", "yield", "block_given\\?", "require", "include", "extend",
                 "attr_reader", "attr_writer", "attr_accessor",
                 "true", "false", "nil", "self", "super", "then"]),
    HighlightRule(#":\w+"#, attrColor),
    HighlightRule(#"\b[A-Z]\w*\b"#, typeColor),
    numberLiteral,
    doubleQuoteString,
    singleQuoteString,
    hashComment,
]

private let goRules: [HighlightRule] = [
    keywordRule(["package", "import", "func", "var", "const", "type", "struct", "interface",
                 "map", "chan", "if", "else", "for", "range", "switch", "case", "default",
                 "break", "continue", "return", "go", "defer", "select", "fallthrough",
                 "true", "false", "nil", "make", "new", "append", "len", "cap"]),
    HighlightRule(#"\b[A-Z]\w*\b"#, typeColor),
    numberLiteral,
    doubleQuoteString,
    backtickString,
    lineComment,
    blockComment,
]

private let rustRules: [HighlightRule] = [
    keywordRule(["fn", "let", "mut", "const", "struct", "enum", "impl", "trait", "type",
                 "use", "mod", "pub", "crate", "self", "super", "if", "else", "match",
                 "for", "while", "loop", "break", "continue", "return", "async", "await",
                 "move", "ref", "where", "as", "in", "unsafe", "extern",
                 "true", "false", "Some", "None", "Ok", "Err"]),
    HighlightRule(#"\b[A-Z]\w*\b"#, typeColor),
    numberLiteral,
    doubleQuoteString,
    lineComment,
    blockComment,
]

private let javaRules: [HighlightRule] = [
    keywordRule(["import", "package", "class", "interface", "extends", "implements",
                 "public", "private", "protected", "static", "final", "abstract",
                 "void", "return", "if", "else", "for", "while", "do", "switch", "case",
                 "break", "continue", "new", "this", "super", "try", "catch", "finally",
                 "throw", "throws", "synchronized", "volatile",
                 "true", "false", "null", "instanceof"]),
    HighlightRule(#"@\w+"#, attrColor),
    HighlightRule(#"\b[A-Z]\w*\b"#, typeColor),
    numberLiteral,
    doubleQuoteString,
    singleQuoteString,
    lineComment,
    blockComment,
]

private let cRules: [HighlightRule] = [
    keywordRule(["include", "define", "ifdef", "ifndef", "endif", "pragma",
                 "int", "float", "double", "char", "void", "long", "short", "unsigned", "signed",
                 "struct", "union", "enum", "typedef", "const", "static", "extern", "volatile",
                 "if", "else", "for", "while", "do", "switch", "case", "default",
                 "break", "continue", "return", "sizeof", "goto",
                 "NULL", "true", "false", "nil", "self", "super",
                 "class", "public", "private", "protected", "virtual", "override",
                 "namespace", "using", "template", "typename",
                 "YES", "NO", "BOOL", "NSObject", "NSString"]),
    HighlightRule(#"#\w+"#, attrColor),
    HighlightRule(#"\b[A-Z]\w*\b"#, typeColor),
    numberLiteral,
    doubleQuoteString,
    singleQuoteString,
    lineComment,
    blockComment,
]

private let cssRules: [HighlightRule] = [
    HighlightRule(#"[.#][\w-]+"#, typeColor),
    HighlightRule(#"[\w-]+(?=\s*:)"#, keywordColor),
    numberLiteral,
    HighlightRule(#"#[0-9a-fA-F]{3,8}\b"#, numberColor),
    doubleQuoteString,
    singleQuoteString,
    blockComment,
]

private let htmlRules: [HighlightRule] = [
    HighlightRule(#"</?[\w-]+"#, keywordColor),
    HighlightRule(#"/?\s*>"#, keywordColor),
    HighlightRule(#"\b[\w-]+(?=\s*=)"#, attrColor),
    doubleQuoteString,
    singleQuoteString,
    HighlightRule(#"<!--[\s\S]*?-->"#, commentColor, italic: true),
]

private let jsonRules: [HighlightRule] = [
    HighlightRule(#""[^"]*"\s*(?=:)"#, keywordColor),
    numberLiteral,
    keywordRule(["true", "false", "null"]),
    doubleQuoteString,
]

private let yamlRules: [HighlightRule] = [
    HighlightRule(#"^[\w.-]+(?=\s*:)"#, keywordColor, options: .anchorsMatchLines),
    numberLiteral,
    keywordRule(["true", "false", "null", "yes", "no"]),
    doubleQuoteString,
    singleQuoteString,
    hashComment,
]

private let shellRules: [HighlightRule] = [
    keywordRule(["if", "then", "else", "elif", "fi", "for", "while", "do", "done",
                 "case", "esac", "in", "function", "return", "exit",
                 "echo", "export", "local", "readonly", "set", "unset", "source"]),
    HighlightRule(#"\$[\w{]+"#, typeColor),
    numberLiteral,
    doubleQuoteString,
    singleQuoteString,
    hashComment,
]

private let sqlRules: [HighlightRule] = [
    keywordRule(["SELECT", "FROM", "WHERE", "INSERT", "INTO", "VALUES", "UPDATE", "SET",
                 "DELETE", "CREATE", "TABLE", "ALTER", "DROP", "INDEX", "JOIN", "LEFT",
                 "RIGHT", "INNER", "OUTER", "ON", "AND", "OR", "NOT", "NULL", "IS",
                 "IN", "LIKE", "BETWEEN", "ORDER", "BY", "GROUP", "HAVING", "LIMIT",
                 "AS", "DISTINCT", "COUNT", "SUM", "AVG", "MAX", "MIN",
                 "select", "from", "where", "insert", "into", "values", "update", "set",
                 "delete", "create", "table", "alter", "drop", "index", "join", "left",
                 "right", "inner", "outer", "on", "and", "or", "not", "null", "is",
                 "in", "like", "between", "order", "by", "group", "having", "limit",
                 "as", "distinct", "count", "sum", "avg", "max", "min"]),
    numberLiteral,
    singleQuoteString,
    HighlightRule(#"--.*$"#, commentColor, options: .anchorsMatchLines, italic: true),
    blockComment,
]

private let genericRules: [HighlightRule] = [
    numberLiteral,
    doubleQuoteString,
    singleQuoteString,
    lineComment,
    hashComment,
    blockComment,
]
