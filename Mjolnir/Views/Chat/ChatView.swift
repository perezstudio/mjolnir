import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var appState: AppState
    var terminalManager: TerminalManager
    @State private var viewModel = ChatViewModel()
    @State private var showRunCommandSheet = false
    @State private var runCommandDraft = ""

    var body: some View {
        Group {
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
    }

    // MARK: - Chat Content

    private func chatContent(for chat: Chat) -> some View {
        messageList(for: chat)
            .safeAreaInset(edge: .top, spacing: 0) {
                ChatHeaderView(
                    chat: chat,
                    appState: appState,
                    isProcessing: viewModel.isProcessing,
                    onCancel: { viewModel.cancelGeneration() },
                    onRunCommand: { handleRunCommand(chat: chat) },
                    onConfigureRunCommand: { showRunSettings(chat: chat) }
                )
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                floatingInputArea(for: chat)
            }
            .sheet(isPresented: $showRunCommandSheet) {
                runCommandSheet(chat: chat)
            }
    }

    // MARK: - Floating Input Area

    private func floatingInputArea(for chat: Chat) -> some View {
        VStack(spacing: 8) {
            if let error = viewModel.errorMessage {
                errorBanner(error)
                    .padding(.horizontal, 16)
            }

            ChatInputView(
                text: $viewModel.inputText,
                selectedModel: $viewModel.selectedModel,
                permissionMode: $viewModel.permissionMode,
                isProcessing: viewModel.isProcessing,
                onSend: { viewModel.sendMessage(chat: chat, modelContext: modelContext) },
                onCancel: { viewModel.cancelGeneration() }
            )
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1)))
            .shadow(color: .black.opacity(0.15), radius: 8, y: -2)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
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
                Spacer()
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
                .padding(16)
                .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.bottom)
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
                .imageScale(.large)
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
