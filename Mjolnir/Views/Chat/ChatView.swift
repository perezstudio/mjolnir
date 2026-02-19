import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var appState: AppState
    @State private var viewModel = ChatViewModel()
    @State private var terminalManager = TerminalManager()
    @State private var showRunCommandSheet = false
    @State private var runCommandDraft = ""

    var body: some View {
        VStack(spacing: 0) {
            if let chat = appState.selectedChat {
                chatContent(for: chat)
            } else {
                emptyChatState
            }
        }
        .onChange(of: appState.selectedChat?.id) { _, _ in
            if let chat = appState.selectedChat {
                viewModel.loadChat(chat)
                terminalManager.reset()
            }
        }
        .onChange(of: appState.isTerminalVisible) { _, visible in
            if visible, terminalManager.sessions.isEmpty,
               let chat = appState.selectedChat {
                terminalManager.addSession(workingDirectory: chat.workingDirectory)
            }
        }
    }

    // MARK: - Chat Content

    @ViewBuilder
    private func chatContent(for chat: Chat) -> some View {
        ChatHeaderView(
            chat: chat,
            appState: appState,
            isProcessing: viewModel.isProcessing,
            onCancel: { viewModel.cancelGeneration() },
            onRunCommand: { handleRunCommand(chat: chat) },
            onConfigureRunCommand: { showRunSettings(chat: chat) }
        )
        Divider()
        messageList(for: chat)

        if let error = viewModel.errorMessage {
            errorBanner(error)
        }

        Divider()
        ChatInputView(
            text: $viewModel.inputText,
            selectedModel: $viewModel.selectedModel,
            permissionMode: $viewModel.permissionMode,
            isProcessing: viewModel.isProcessing,
            onSend: { viewModel.sendMessage(chat: chat, modelContext: modelContext) },
            onCancel: { viewModel.cancelGeneration() }
        )

        // Terminal area — below the input, at the very bottom
        TerminalAreaView(
            manager: terminalManager,
            workingDirectory: chat.workingDirectory
        )
        .frame(height: appState.isTerminalVisible ? 200 : 0)
        .clipped()
        .animation(.easeInOut(duration: 0.2), value: appState.isTerminalVisible)

        // Run command configuration sheet
        .sheet(isPresented: $showRunCommandSheet) {
            runCommandSheet(chat: chat)
        }
    }

    // MARK: - Run Command

    private func handleRunCommand(chat: Chat) {
        guard let runCommand = chat.project?.runCommand, !runCommand.isEmpty else {
            runCommandDraft = chat.project?.runCommand ?? ""
            showRunCommandSheet = true
            return
        }

        // Show terminal if hidden
        if !appState.isTerminalVisible {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.isTerminalVisible = true
            }
        }

        // Add a new terminal session and run the command
        terminalManager.addSession(
            workingDirectory: chat.workingDirectory,
            title: "Run",
            command: runCommand
        )
    }

    private func showRunSettings(chat: Chat) {
        runCommandDraft = chat.project?.runCommand ?? ""
        showRunCommandSheet = true
    }

    private func runCommandSheet(chat: Chat) -> some View {
        VStack(spacing: 16) {
            Text("Configure Run Command")
                .font(.headline)
            TextField("e.g. npm start, swift run, make", text: $runCommandDraft)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") {
                    showRunCommandSheet = false
                }
                Spacer()
                Button("Save") {
                    chat.project?.runCommand = runCommandDraft
                    showRunCommandSheet = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 360)
    }

    // MARK: - Message List

    private func messageList(for chat: Chat) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    let sorted = chat.messages.sorted { $0.createdAt < $1.createdAt }
                    ForEach(sorted) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }

                    // Streaming assistant message (not yet persisted)
                    if viewModel.isProcessing || !viewModel.streamingText.isEmpty {
                        StreamingMessageView(
                            text: viewModel.streamingText,
                            toolCalls: viewModel.streamingToolCalls,
                            isProcessing: viewModel.isProcessing
                        )
                        .id("streaming")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.streamingText) { _, _ in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }
            .onChange(of: chat.messages.count) { _, _ in
                if let last = chat.messages.sorted(by: { $0.createdAt < $1.createdAt }).last {
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyChatState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("Select a chat to start")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption)
                .lineLimit(2)
            Spacer()
            Button("Dismiss") {
                viewModel.errorMessage = nil
            }
            .font(.caption)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
    }
}
