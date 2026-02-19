import Foundation

// All CLI message types are nonisolated and Sendable so they can cross actor boundaries.

// MARK: - Top-Level CLI Message (SDKMessage union)

nonisolated enum CLIMessage: Sendable {
    case system(CLISystemMessage)
    case assistant(CLIAssistantMessage)
    case user(CLIUserMessage)
    case result(CLIResultMessage)
    case streamEvent(CLIStreamEvent)
    case toolProgress(CLIToolProgressMessage)
    case toolUseSummary(CLIToolUseSummaryMessage)
    case authStatus(CLIAuthStatusMessage)
    case rateLimit(CLIRateLimitEvent)
    case unknown(type: String, raw: String)
}

extension CLIMessage: Decodable {
    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "system":
            self = .system(try CLISystemMessage(from: decoder))
        case "assistant":
            self = .assistant(try CLIAssistantMessage(from: decoder))
        case "user":
            self = .user(try CLIUserMessage(from: decoder))
        case "result":
            self = .result(try CLIResultMessage(from: decoder))
        case "stream_event":
            self = .streamEvent(try CLIStreamEvent(from: decoder))
        case "tool_progress":
            self = .toolProgress(try CLIToolProgressMessage(from: decoder))
        case "tool_use_summary":
            self = .toolUseSummary(try CLIToolUseSummaryMessage(from: decoder))
        case "auth_status":
            self = .authStatus(try CLIAuthStatusMessage(from: decoder))
        case "rate_limit_event":
            self = .rateLimit(try CLIRateLimitEvent(from: decoder))
        default:
            self = .unknown(type: type, raw: "")
        }
    }
}

// MARK: - System Messages (type: "system", discriminated by subtype)

enum CLISystemMessage {
    case `init`(CLISystemInit)
    case compactBoundary(CLICompactBoundary)
    case status(CLIStatusMessage)
    case hookStarted(CLIHookStarted)
    case hookProgress(CLIHookProgress)
    case hookResponse(CLIHookResponse)
    case taskStarted(CLITaskStarted)
    case taskNotification(CLITaskNotification)
    case filesPersisted(CLIFilesPersisted)
    case unknown(subtype: String)
}

extension CLISystemMessage: Decodable {
    private enum CodingKeys: String, CodingKey {
        case subtype
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let subtype = try container.decode(String.self, forKey: .subtype)

        switch subtype {
        case "init":
            self = .`init`(try CLISystemInit(from: decoder))
        case "compact_boundary":
            self = .compactBoundary(try CLICompactBoundary(from: decoder))
        case "status":
            self = .status(try CLIStatusMessage(from: decoder))
        case "hook_started":
            self = .hookStarted(try CLIHookStarted(from: decoder))
        case "hook_progress":
            self = .hookProgress(try CLIHookProgress(from: decoder))
        case "hook_response":
            self = .hookResponse(try CLIHookResponse(from: decoder))
        case "task_started":
            self = .taskStarted(try CLITaskStarted(from: decoder))
        case "task_notification":
            self = .taskNotification(try CLITaskNotification(from: decoder))
        case "files_persisted":
            self = .filesPersisted(try CLIFilesPersisted(from: decoder))
        default:
            self = .unknown(subtype: subtype)
        }
    }
}

struct CLISystemInit: Decodable {
    let cwd: String
    let sessionId: String
    let tools: [String]
    let mcpServers: [MCPServerInfo]
    let model: String
    let permissionMode: String
    let slashCommands: [String]
    let outputStyle: String
    let agents: [String]?
    let skills: [String]?
    let plugins: [PluginInfo]?
    let claudeCodeVersion: String
    let apiKeySource: String
    let uuid: String
    let fastModeState: String?

    enum CodingKeys: String, CodingKey {
        case cwd, tools, model, agents, skills, plugins, uuid
        case sessionId = "session_id"
        case mcpServers = "mcp_servers"
        case permissionMode = "permissionMode"
        case slashCommands = "slash_commands"
        case outputStyle = "output_style"
        case claudeCodeVersion = "claude_code_version"
        case apiKeySource = "apiKeySource"
        case fastModeState = "fast_mode_state"
    }
}

struct MCPServerInfo: Decodable {
    let name: String
    let status: String
}

struct PluginInfo: Decodable {
    let name: String
    let path: String
}

struct CLICompactBoundary: Decodable {
    let compactMetadata: CompactMetadata
    let uuid: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case uuid
        case compactMetadata = "compact_metadata"
        case sessionId = "session_id"
    }
}

struct CompactMetadata: Decodable {
    let trigger: String      // "manual" | "auto"
    let preTokens: Int

    enum CodingKeys: String, CodingKey {
        case trigger
        case preTokens = "pre_tokens"
    }
}

struct CLIStatusMessage: Decodable {
    let status: String?       // "compacting" | null
    let permissionMode: String?
    let uuid: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case status, permissionMode, uuid
        case sessionId = "session_id"
    }
}

struct CLIHookStarted: Decodable {
    let hookId: String
    let hookName: String
    let hookEvent: String
    let uuid: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case uuid
        case hookId = "hook_id"
        case hookName = "hook_name"
        case hookEvent = "hook_event"
        case sessionId = "session_id"
    }
}

struct CLIHookProgress: Decodable {
    let hookId: String
    let hookName: String
    let hookEvent: String
    let stdout: String
    let stderr: String
    let output: String
    let uuid: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case stdout, stderr, output, uuid
        case hookId = "hook_id"
        case hookName = "hook_name"
        case hookEvent = "hook_event"
        case sessionId = "session_id"
    }
}

struct CLIHookResponse: Decodable {
    let hookId: String
    let hookName: String
    let hookEvent: String
    let output: String
    let stdout: String
    let stderr: String
    let exitCode: Int?
    let outcome: String       // "success" | "error" | "cancelled"
    let uuid: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case output, stdout, stderr, outcome, uuid
        case hookId = "hook_id"
        case hookName = "hook_name"
        case hookEvent = "hook_event"
        case exitCode = "exit_code"
        case sessionId = "session_id"
    }
}

struct CLITaskStarted: Decodable {
    let taskId: String
    let toolUseId: String?
    let description: String
    let taskType: String?
    let uuid: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case description, uuid
        case taskId = "task_id"
        case toolUseId = "tool_use_id"
        case taskType = "task_type"
        case sessionId = "session_id"
    }
}

struct CLITaskNotification: Decodable {
    let taskId: String
    let toolUseId: String?
    let status: String         // "completed" | "failed" | "stopped"
    let outputFile: String
    let summary: String
    let uuid: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case status, summary, uuid
        case taskId = "task_id"
        case toolUseId = "tool_use_id"
        case outputFile = "output_file"
        case sessionId = "session_id"
    }
}

struct CLIFilesPersisted: Decodable {
    let files: [PersistedFile]
    let failed: [PersistedFileFailed]
    let processedAt: String
    let uuid: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case files, failed, uuid
        case processedAt = "processed_at"
        case sessionId = "session_id"
    }
}

struct PersistedFile: Decodable {
    let filename: String
    let fileId: String

    enum CodingKeys: String, CodingKey {
        case filename
        case fileId = "file_id"
    }
}

struct PersistedFileFailed: Decodable {
    let filename: String
    let error: String
}

// MARK: - Assistant Message (type: "assistant")

struct CLIAssistantMessage: Decodable {
    let message: AssistantMessageContent
    let parentToolUseId: String?
    let error: String?
    let uuid: String?
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case message, error, uuid
        case parentToolUseId = "parent_tool_use_id"
        case sessionId = "session_id"
    }
}

struct AssistantMessageContent: Decodable {
    let id: String
    let model: String
    let role: String
    let content: [ContentBlock]
    let stopReason: String?
    let stopSequence: String?
    let usage: CLIUsage?
    let contextManagement: AnyCodableValue?

    enum CodingKeys: String, CodingKey {
        case id, model, role, content, usage
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
        case contextManagement = "context_management"
    }

    var textContent: String {
        content.compactMap { $0.textValue }.joined()
    }

    var toolUseCalls: [ToolUseContent] {
        content.compactMap {
            if case .toolUse(let t) = $0 { return t }
            return nil
        }
    }
}

// MARK: - User Message (type: "user")

struct CLIUserMessage: Decodable {
    let message: UserMessageContent
    let parentToolUseId: String?
    let isSynthetic: Bool?
    let uuid: String?
    let sessionId: String
    let isReplay: Bool?

    enum CodingKeys: String, CodingKey {
        case message, isSynthetic, uuid, isReplay
        case parentToolUseId = "parent_tool_use_id"
        case sessionId = "session_id"
    }
}

struct UserMessageContent: Decodable {
    let role: String
    let content: AnyCodableValue  // Can be String or [ContentBlockParam]
}

// MARK: - Stream Event (type: "stream_event")

struct CLIStreamEvent: Decodable {
    let event: StreamEventPayload
    let parentToolUseId: String?
    let uuid: String?
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case event, uuid
        case parentToolUseId = "parent_tool_use_id"
        case sessionId = "session_id"
    }
}

enum StreamEventPayload: Decodable {
    case messageStart(StreamMessageStart)
    case messageDelta(StreamMessageDelta)
    case messageStop
    case contentBlockStart(StreamContentBlockStart)
    case contentBlockDelta(StreamContentBlockDelta)
    case contentBlockStop(index: Int)
    case unknown(String)

    private enum CodingKeys: String, CodingKey {
        case type, index
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "message_start":
            self = .messageStart(try StreamMessageStart(from: decoder))
        case "message_delta":
            self = .messageDelta(try StreamMessageDelta(from: decoder))
        case "message_stop":
            self = .messageStop
        case "content_block_start":
            self = .contentBlockStart(try StreamContentBlockStart(from: decoder))
        case "content_block_delta":
            self = .contentBlockDelta(try StreamContentBlockDelta(from: decoder))
        case "content_block_stop":
            let index = try container.decode(Int.self, forKey: .index)
            self = .contentBlockStop(index: index)
        default:
            self = .unknown(type)
        }
    }
}

struct StreamMessageStart: Decodable {
    let message: AssistantMessageContent
}

struct StreamMessageDelta: Decodable {
    let delta: MessageDelta
    let usage: MessageDeltaUsage?
}

struct MessageDelta: Decodable {
    let stopReason: String?
    let stopSequence: String?

    enum CodingKeys: String, CodingKey {
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
    }
}

struct MessageDeltaUsage: Decodable {
    let inputTokens: Int?
    let outputTokens: Int
    let cacheReadInputTokens: Int?
    let cacheCreationInputTokens: Int?

    enum CodingKeys: String, CodingKey {
        case outputTokens = "output_tokens"
        case inputTokens = "input_tokens"
        case cacheReadInputTokens = "cache_read_input_tokens"
        case cacheCreationInputTokens = "cache_creation_input_tokens"
    }
}

struct StreamContentBlockStart: Decodable {
    let index: Int
    let contentBlock: ContentBlock

    enum CodingKeys: String, CodingKey {
        case index
        case contentBlock = "content_block"
    }
}

struct StreamContentBlockDelta: Decodable {
    let index: Int
    let delta: ContentBlockDelta
}

enum ContentBlockDelta: Decodable {
    case textDelta(String)
    case inputJsonDelta(String)
    case thinkingDelta(String)
    case signatureDelta(String)
    case citationsDelta(AnyCodableValue)
    case compactionDelta(String?)
    case unknown(String)

    private enum CodingKeys: String, CodingKey {
        case type, text
        case partialJson = "partial_json"
        case thinking, signature, citation, content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text_delta":
            let text = try container.decode(String.self, forKey: .text)
            self = .textDelta(text)
        case "input_json_delta":
            let json = try container.decode(String.self, forKey: .partialJson)
            self = .inputJsonDelta(json)
        case "thinking_delta":
            let thinking = try container.decode(String.self, forKey: .thinking)
            self = .thinkingDelta(thinking)
        case "signature_delta":
            let sig = try container.decode(String.self, forKey: .signature)
            self = .signatureDelta(sig)
        case "citations_delta":
            let citation = try container.decode(AnyCodableValue.self, forKey: .citation)
            self = .citationsDelta(citation)
        case "compaction_delta":
            let content = try container.decodeIfPresent(String.self, forKey: .content)
            self = .compactionDelta(content)
        default:
            self = .unknown(type)
        }
    }

    var textValue: String? {
        if case .textDelta(let text) = self { return text }
        return nil
    }
}

// MARK: - Content Blocks

enum ContentBlock: Decodable {
    case text(TextContent)
    case thinking(ThinkingContent)
    case redactedThinking(RedactedThinkingContent)
    case toolUse(ToolUseContent)
    case serverToolUse(ServerToolUseContent)
    case mcpToolUse(MCPToolUseContent)
    case mcpToolResult(MCPToolResultContent)
    case compaction(CompactionContent)
    case webSearchResult(AnyCodableValue)
    case webFetchResult(AnyCodableValue)
    case unknown(String)

    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            self = .text(try TextContent(from: decoder))
        case "thinking":
            self = .thinking(try ThinkingContent(from: decoder))
        case "redacted_thinking":
            self = .redactedThinking(try RedactedThinkingContent(from: decoder))
        case "tool_use":
            self = .toolUse(try ToolUseContent(from: decoder))
        case "server_tool_use":
            self = .serverToolUse(try ServerToolUseContent(from: decoder))
        case "mcp_tool_use":
            self = .mcpToolUse(try MCPToolUseContent(from: decoder))
        case "mcp_tool_result":
            self = .mcpToolResult(try MCPToolResultContent(from: decoder))
        case "compaction":
            self = .compaction(try CompactionContent(from: decoder))
        case "web_search_tool_result":
            self = .webSearchResult(try AnyCodableValue(from: decoder))
        case "web_fetch_tool_result":
            self = .webFetchResult(try AnyCodableValue(from: decoder))
        default:
            self = .unknown(type)
        }
    }

    var textValue: String? {
        if case .text(let content) = self { return content.text }
        return nil
    }
}

struct TextContent: Decodable {
    let text: String
    let citations: [AnyCodableValue]?
}

struct ThinkingContent: Decodable {
    let thinking: String
    let signature: String
}

struct RedactedThinkingContent: Decodable {
    let data: String
}

struct ToolUseContent: Decodable {
    let id: String
    let name: String
    let input: [String: AnyCodableValue]
}

struct ServerToolUseContent: Decodable {
    let id: String
    let name: String
    let input: [String: AnyCodableValue]
}

struct MCPToolUseContent: Decodable {
    let id: String
    let name: String
    let serverName: String
    let input: AnyCodableValue

    enum CodingKeys: String, CodingKey {
        case id, name, input
        case serverName = "server_name"
    }
}

struct MCPToolResultContent: Decodable {
    let toolUseId: String
    let content: AnyCodableValue  // String or [TextContent]
    let isError: Bool

    enum CodingKeys: String, CodingKey {
        case content
        case toolUseId = "tool_use_id"
        case isError = "is_error"
    }
}

struct CompactionContent: Decodable {
    let content: String?
}

// MARK: - Result Message (type: "result")

struct CLIResultMessage: Decodable {
    let subtype: String          // "success" | "error_during_execution" | "error_max_turns" | "error_max_budget_usd"
    let isError: Bool
    let durationMs: Int
    let durationApiMs: Int?
    let numTurns: Int
    let result: String?          // Present on success
    let errors: [String]?        // Present on error subtypes
    let stopReason: String?
    let sessionId: String
    let totalCostUsd: Double
    let usage: CLIUsageAggregate?
    let modelUsage: [String: ModelUsage]?
    let permissionDenials: [PermissionDenial]?
    let uuid: String?

    enum CodingKeys: String, CodingKey {
        case subtype, result, errors, usage, modelUsage, uuid
        case isError = "is_error"
        case durationMs = "duration_ms"
        case durationApiMs = "duration_api_ms"
        case numTurns = "num_turns"
        case stopReason = "stop_reason"
        case sessionId = "session_id"
        case totalCostUsd = "total_cost_usd"
        case permissionDenials = "permission_denials"
    }

    var isSuccess: Bool { subtype == "success" }
}

struct ModelUsage: Decodable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadInputTokens: Int
    let cacheCreationInputTokens: Int
    let webSearchRequests: Int?
    let costUSD: Double
    let contextWindow: Int
    let maxOutputTokens: Int
}

struct PermissionDenial: Decodable {
    let toolName: String
    let toolUseId: String
    let toolInput: [String: AnyCodableValue]?

    enum CodingKeys: String, CodingKey {
        case toolName = "tool_name"
        case toolUseId = "tool_use_id"
        case toolInput = "tool_input"
    }
}

// MARK: - Tool Progress (type: "tool_progress")

struct CLIToolProgressMessage: Decodable {
    let toolUseId: String
    let toolName: String
    let parentToolUseId: String?
    let elapsedTimeSeconds: Double
    let taskId: String?
    let uuid: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case uuid
        case toolUseId = "tool_use_id"
        case toolName = "tool_name"
        case parentToolUseId = "parent_tool_use_id"
        case elapsedTimeSeconds = "elapsed_time_seconds"
        case taskId = "task_id"
        case sessionId = "session_id"
    }
}

// MARK: - Tool Use Summary (type: "tool_use_summary")

struct CLIToolUseSummaryMessage: Decodable {
    let summary: String
    let precedingToolUseIds: [String]
    let uuid: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case summary, uuid
        case precedingToolUseIds = "preceding_tool_use_ids"
        case sessionId = "session_id"
    }
}

// MARK: - Auth Status (type: "auth_status")

struct CLIAuthStatusMessage: Decodable {
    let isAuthenticating: Bool
    let output: [String]
    let error: String?
    let uuid: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case isAuthenticating, output, error, uuid
        case sessionId = "session_id"
    }
}

// MARK: - Rate Limit Event (type: "rate_limit_event")

struct CLIRateLimitEvent: Decodable {
    let rateLimitInfo: RateLimitInfo
    let uuid: String?
    let sessionId: String?

    enum CodingKeys: String, CodingKey {
        case uuid
        case rateLimitInfo = "rate_limit_info"
        case sessionId = "session_id"
    }
}

struct RateLimitInfo: Decodable {
    let status: String           // "allowed" | "rate_limited"
    let resetsAt: Int?
    let rateLimitType: String?
    let overageStatus: String?
    let overageDisabledReason: String?
    let isUsingOverage: Bool?
}

// MARK: - Usage Types

struct CLIUsage: Decodable {
    let inputTokens: Int?
    let outputTokens: Int?
    let cacheReadInputTokens: Int?
    let cacheCreationInputTokens: Int?
    let cacheCreation: CacheCreation?
    let serviceTier: String?
    let inferenceGeo: String?
    let serverToolUse: ServerToolUsage?

    enum CodingKeys: String, CodingKey {
        case cacheCreation = "cache_creation"
        case serviceTier = "service_tier"
        case inferenceGeo = "inference_geo"
        case serverToolUse = "server_tool_use"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheReadInputTokens = "cache_read_input_tokens"
        case cacheCreationInputTokens = "cache_creation_input_tokens"
    }
}

struct CLIUsageAggregate: Decodable {
    let inputTokens: Int?
    let outputTokens: Int?
    let cacheReadInputTokens: Int?
    let cacheCreationInputTokens: Int?
    let serviceTier: String?
    let speed: String?
    let inferenceGeo: String?
    let serverToolUse: ServerToolUsage?

    enum CodingKeys: String, CodingKey {
        case speed
        case serviceTier = "service_tier"
        case inferenceGeo = "inference_geo"
        case serverToolUse = "server_tool_use"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheReadInputTokens = "cache_read_input_tokens"
        case cacheCreationInputTokens = "cache_creation_input_tokens"
    }
}

struct CacheCreation: Decodable {
    let ephemeral1hInputTokens: Int?
    let ephemeral5mInputTokens: Int?

    enum CodingKeys: String, CodingKey {
        case ephemeral1hInputTokens = "ephemeral_1h_input_tokens"
        case ephemeral5mInputTokens = "ephemeral_5m_input_tokens"
    }
}

struct ServerToolUsage: Decodable {
    let webSearchRequests: Int?
    let webFetchRequests: Int?

    enum CodingKeys: String, CodingKey {
        case webSearchRequests = "web_search_requests"
        case webFetchRequests = "web_fetch_requests"
    }
}

// MARK: - Stop Reasons

enum StopReason: String, Decodable {
    case endTurn = "end_turn"
    case maxTokens = "max_tokens"
    case stopSequence = "stop_sequence"
    case toolUse = "tool_use"
    case pauseTurn = "pause_turn"
    case compaction = "compaction"
    case refusal = "refusal"
    case modelContextWindowExceeded = "model_context_window_exceeded"
}

// MARK: - AnyCodableValue (for arbitrary JSON)

enum AnyCodableValue: Decodable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case dictionary([String: AnyCodableValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([AnyCodableValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(value)
        } else {
            self = .null
        }
    }

    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    var intValue: Int? {
        if case .int(let v) = self { return v }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }

    var description: String {
        switch self {
        case .string(let v): return "\"\(v)\""
        case .int(let v): return "\(v)"
        case .double(let v): return "\(v)"
        case .bool(let v): return "\(v)"
        case .null: return "null"
        case .array(let v): return "[\(v.map(\.description).joined(separator: ", "))]"
        case .dictionary(let v):
            let pairs = v.map { "\"\($0.key)\": \($0.value.description)" }
            return "{\(pairs.joined(separator: ", "))}"
        }
    }
}
