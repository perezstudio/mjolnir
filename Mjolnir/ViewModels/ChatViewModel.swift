import Foundation
import SwiftData

enum PermissionMode: String, CaseIterable {
    case ask = "default"
    case autoAcceptEdits = "auto-accept-edits"
    case planMode = "plan"

    var label: String {
        switch self {
        case .ask: return "Ask Permissions"
        case .autoAcceptEdits: return "Auto Accept Edits"
        case .planMode: return "Plan Mode"
        }
    }

    var icon: String {
        switch self {
        case .ask: return "hand.raised"
        case .autoAcceptEdits: return "wand.and.sparkles.inverse"
        case .planMode: return "scroll"
        }
    }

    var description: String {
        switch self {
        case .ask: return "Always ask before making changes"
        case .autoAcceptEdits: return "Automatically accept all file edits"
        case .planMode: return "Create a plan before making changes"
        }
    }
}

struct StreamingToolCall: Identifiable {
    let id: String
    let name: String
    var inputJson: String
    var isComplete: Bool
    var elapsedSeconds: Double = 0
}

@Observable
final class ChatViewModel {

    // MARK: - UI State

    var streamingText: String = ""
    var streamingToolCalls: [StreamingToolCall] = []
    var isProcessing: Bool = false
    var selectedModel: String = "claude-sonnet-4-20250514"
    var permissionMode: PermissionMode = .ask
    var inputText: String = ""
    var errorMessage: String?
    var inputTokens: Int = 0
    var outputTokens: Int = 0

    // MARK: - Dependencies

    private let cliService = ClaudeCLIService.shared
    private let sessionManager = CLISessionManager()
    private var streamTask: Task<Void, Never>?
    private var didPersistMessage = false

    // MARK: - Send Message

    func sendMessage(chat: Chat, modelContext: ModelContext) {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isProcessing else { return }

        // Persist user message
        let userMessage = Message(role: "user", content: text, chat: chat)
        modelContext.insert(userMessage)
        try? modelContext.save()

        // Reset state
        inputText = ""
        streamingText = ""
        streamingToolCalls = []
        isProcessing = true
        errorMessage = nil
        didPersistMessage = false
        inputTokens = 0
        outputTokens = 0

        // Start CLI stream
        let sessionId = sessionManager.resumeSessionID(for: chat)
        let workingDir = chat.workingDirectory
        let model = selectedModel
        let systemPrompt = chat.project?.systemPrompt
        let permission = permissionMode.rawValue

        streamTask = Task {
            let stream = await cliService.sendMessage(
                prompt: text,
                model: model,
                workingDirectory: workingDir,
                sessionID: sessionId,
                systemPrompt: systemPrompt,
                permissionMode: permission
            )
            await processStream(stream, chat: chat, modelContext: modelContext)
        }
    }

    // MARK: - Cancel

    func cancelGeneration() {
        streamTask?.cancel()
        streamTask = nil
        Task { await cliService.cancel() }
        isProcessing = false
    }

    // MARK: - Load Chat

    func loadChat(_ chat: Chat) {
        cancelGeneration()
        streamingText = ""
        streamingToolCalls = []
        errorMessage = nil
        inputTokens = 0
        outputTokens = 0
    }

    // MARK: - Stream Processing

    private func processStream(
        _ stream: AsyncThrowingStream<CLIMessage, Error>,
        chat: Chat,
        modelContext: ModelContext
    ) async {
        do {
            for try await message in stream {
                if Task.isCancelled { break }

                switch message {
                case .system(let sys):
                    handleSystemMessage(sys, chat: chat)
                case .streamEvent(let event):
                    handleStreamEvent(event)
                case .assistant(let msg):
                    handleAssistantMessage(msg, chat: chat, modelContext: modelContext)
                case .result(let result):
                    handleResult(result, chat: chat, modelContext: modelContext)
                case .toolProgress(let progress):
                    handleToolProgress(progress)
                default:
                    break
                }
            }
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }

        // Finalize: persist if we have streaming content that wasn't saved yet
        if !streamingText.isEmpty && !didPersistMessage {
            persistAssistantMessage(chat: chat, modelContext: modelContext)
        }
        isProcessing = false
    }

    // MARK: - Message Handlers

    private func handleSystemMessage(_ msg: CLISystemMessage, chat: Chat) {
        if case .`init`(let initData) = msg {
            sessionManager.handleSessionInit(initData, chat: chat)
        }
    }

    private func handleStreamEvent(_ event: CLIStreamEvent) {
        switch event.event {
        case .contentBlockStart(let start):
            switch start.contentBlock {
            case .toolUse(let toolUse):
                streamingToolCalls.append(StreamingToolCall(
                    id: toolUse.id,
                    name: toolUse.name,
                    inputJson: "",
                    isComplete: false
                ))
            default:
                break
            }

        case .contentBlockDelta(let delta):
            switch delta.delta {
            case .textDelta(let text):
                streamingText += text
            case .inputJsonDelta(let json):
                if !streamingToolCalls.isEmpty {
                    streamingToolCalls[streamingToolCalls.count - 1].inputJson += json
                }
            default:
                break
            }

        case .contentBlockStop:
            if let lastIndex = streamingToolCalls.indices.last,
               !streamingToolCalls[lastIndex].isComplete {
                streamingToolCalls[lastIndex].isComplete = true
            }

        case .messageDelta(let delta):
            if let usage = delta.usage {
                outputTokens += usage.outputTokens
            }

        case .messageStart(let start):
            if let usage = start.message.usage {
                inputTokens = usage.inputTokens ?? 0
            }

        default:
            break
        }
    }

    private func handleAssistantMessage(
        _ msg: CLIAssistantMessage,
        chat: Chat,
        modelContext: ModelContext
    ) {
        // Full assistant message (non-streaming path or final message)
        let textContent = msg.message.textContent
        if !textContent.isEmpty && streamingText.isEmpty {
            streamingText = textContent
        }

        if let usage = msg.message.usage {
            inputTokens = usage.inputTokens ?? inputTokens
            outputTokens = usage.outputTokens ?? outputTokens
        }
    }

    private func handleResult(
        _ result: CLIResultMessage,
        chat: Chat,
        modelContext: ModelContext
    ) {
        if let usage = result.usage {
            inputTokens = usage.inputTokens ?? inputTokens
            outputTokens = usage.outputTokens ?? outputTokens
        }

        if !didPersistMessage && !streamingText.isEmpty {
            persistAssistantMessage(
                chat: chat,
                modelContext: modelContext,
                stopReason: result.stopReason
            )
        }
    }

    private func handleToolProgress(_ progress: CLIToolProgressMessage) {
        if let index = streamingToolCalls.firstIndex(where: { $0.id == progress.toolUseId }) {
            streamingToolCalls[index].elapsedSeconds = progress.elapsedTimeSeconds
        }
    }

    // MARK: - Persistence

    @discardableResult
    private func persistAssistantMessage(
        chat: Chat,
        modelContext: ModelContext,
        stopReason: String? = nil
    ) -> Message {
        let message = Message(role: "assistant", content: streamingText, chat: chat)
        message.inputTokens = inputTokens
        message.outputTokens = outputTokens
        message.modelID = selectedModel
        message.stopReason = stopReason
        modelContext.insert(message)

        for tc in streamingToolCalls {
            let toolCall = ToolCall(
                toolUseID: tc.id,
                toolName: tc.name,
                inputJSON: tc.inputJson,
                message: message
            )
            toolCall.status = tc.isComplete ? "completed" : "pending"
            modelContext.insert(toolCall)
        }

        try? modelContext.save()
        didPersistMessage = true

        streamingText = ""
        streamingToolCalls = []
        return message
    }
}
