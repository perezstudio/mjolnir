import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    @Binding var selectedModel: String
    @Binding var permissionMode: PermissionMode
    let isProcessing: Bool
    let onSend: () -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    private let models = [
        ("claude-sonnet-4-20250514", "Sonnet"),
        ("claude-opus-4-20250514", "Opus"),
        ("claude-haiku-3-5-20241022", "Haiku"),
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Text field — full width
            TextField("Message Claude...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...10)
                .focused($isFocused)
                .onSubmit {
                    if !isProcessing && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }
                .onAppear { isFocused = true }

            // Bottom row: selectors on left, send button on right
            HStack(spacing: 8) {
                // Model selector
                Picker("Model", selection: $selectedModel) {
                    ForEach(models, id: \.0) { id, name in
                        Text(name).tag(id)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()

                // Permission selector
                Picker(selection: $permissionMode) {
                    ForEach(PermissionMode.allCases, id: \.self) { mode in
                        Label {
                            Text(mode.label)
                            Text(mode.description)
                        } icon: {
                            Image(systemName: mode.icon)
                        }
                        .tag(mode)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: permissionMode.icon)
                            .font(.caption)
                        Text(permissionMode.label)
                            .font(.caption)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()

                Spacer()

                // Send / Cancel button
                if isProcessing {
                    Button(action: onCancel) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Cancel generation")
                } else {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(
                                text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Color.secondary : Color.accentColor
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("Send message")
                }
            }
        }
        .padding(16)
    }
}
