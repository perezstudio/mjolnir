import SwiftUI

struct InspectorView: View {
    @Bindable var appState: AppState
    @State private var viewModel = InspectorViewModel()

    private var workingDirectory: String {
        appState.selectedChat?.workingDirectory ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            inspectorHeader
            Divider()

            // Tab content
            switch viewModel.selectedTab {
            case .files:
                FileTreeView(
                    rootNode: viewModel.fileTree,
                    isLoading: viewModel.isLoading
                )
            case .modified:
                ModifiedFilesView(
                    files: viewModel.modifiedFiles,
                    isLoading: viewModel.isLoading,
                    onSelectFile: { file in
                        viewModel.loadDiff(for: file, workingDirectory: workingDirectory)
                    }
                )
            }

            if let error = viewModel.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .lineLimit(2)
                    Spacer()
                    Button {
                        viewModel.errorMessage = nil
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
            }

            Spacer(minLength: 0)

            // Bottom area: discard button + commit input (modified tab only)
            if viewModel.selectedTab == .modified {
                inspectorBottomArea
            }
        }
        .onChange(of: appState.selectedChat?.id) { _, _ in
            viewModel.clearDiff()
            viewModel.stopWatching()
            viewModel.refresh(workingDirectory: workingDirectory)
            viewModel.startWatching(workingDirectory: workingDirectory)
        }
        .onChange(of: viewModel.diffState.isReady) { _, isReady in
            if isReady {
                DiffWindowController.open(
                    filePath: viewModel.diffState.filePath,
                    oldContent: viewModel.diffState.oldContent,
                    newContent: viewModel.diffState.newContent
                )
                viewModel.clearDiff()
            }
        }
        .onAppear {
            viewModel.refresh(workingDirectory: workingDirectory)
            viewModel.startWatching(workingDirectory: workingDirectory)
        }
        .onDisappear {
            viewModel.stopWatching()
        }
        .alert("Discard All Changes?", isPresented: $viewModel.showingDiscardConfirmation) {
            Button("Discard", role: .destructive) {
                viewModel.performDiscard(workingDirectory: workingDirectory)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently discard all uncommitted changes. This cannot be undone.")
        }
    }

    // MARK: - Header

    private var inspectorHeader: some View {
        HStack(spacing: 8) {
            // Toggle button on left side of inspector
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.isInspectorVisible = false
                }
            } label: {
                Image(systemName: "sidebar.trailing")
                    .foregroundStyle(Color.secondary)
            }
            .buttonStyle(ToolbarButtonStyle())
            .help("Hide Inspector")

            Spacer()

            // Centered tab picker
            Picker("Tab", selection: $viewModel.selectedTab) {
                ForEach(InspectorTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 180)

            Spacer()

            // Refresh button on right
            Button {
                viewModel.refresh(workingDirectory: workingDirectory)
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(ToolbarButtonStyle())
            .help("Refresh")
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
    }

    // MARK: - Bottom Area

    @ViewBuilder
    private var inspectorBottomArea: some View {
        VStack(spacing: 8) {
            // Discard button — inset, rounded, animated show/hide
            if !viewModel.modifiedFiles.isEmpty {
                Button {
                    viewModel.showingDiscardConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Discard All Changes")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
                    .background(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Commit message input + push button
            HStack(spacing: 8) {
                VStack(spacing: 0) {
                    TextField("Commit message...", text: $viewModel.commitMessage, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...5)
                        .padding(12)

                    HStack(spacing: 8) {
                        // Generate commit message button
                        Button {
                            viewModel.generateCommitMessage(workingDirectory: workingDirectory)
                        } label: {
                            Image(systemName: "wand.and.sparkles.inverse")
                                .fontWeight(.bold)
                                .foregroundStyle(Color.accentColor)
                                .symbolEffect(.pulse, isActive: viewModel.isGeneratingMessage)
                        }
                        .buttonStyle(.plain)
                        .help("Generate commit message")
                        .disabled(viewModel.modifiedFiles.isEmpty || viewModel.isGeneratingMessage)

                        Spacer()

                        // Commit (send) button
                        Button {
                            viewModel.performCommit(workingDirectory: workingDirectory)
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .imageScale(.large)
                                .foregroundStyle(
                                    canCommit ? Color.accentColor : Color.secondary
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canCommit)
                        .help("Commit changes")
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor)))

                // Push button — slides in when there are commits ahead
                if viewModel.commitsAhead > 0 {
                    Button {
                        viewModel.push(workingDirectory: workingDirectory)
                    } label: {
                        VStack(spacing: 4) {
                            if viewModel.isPushing {
                                ProgressView()
                                    .controlSize(.mini)
                            } else {
                                Image(systemName: "icloud.and.arrow.up")


                            }
                            Text("\(viewModel.commitsAhead)")
                                .monospacedDigit()
                        }
                        .foregroundStyle(.white)
                        .frame(minWidth: 36)
                        .frame(maxHeight: .infinity)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .help("Push \(viewModel.commitsAhead) commit(s) to remote")
                    .disabled(viewModel.isPushing)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .animation(.easeInOut(duration: 0.2), value: viewModel.modifiedFiles.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: viewModel.commitsAhead)
    }

    private var canCommit: Bool {
        !viewModel.modifiedFiles.isEmpty
            && !viewModel.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
