# Mjolnir

A native macOS coding assistant app wrapping the Claude Code CLI with full terminal integration, git worktree support, and a custom AppKit interface.

## Build

```bash
xcodebuild -project /Users/keviruchis/Developer/Mjolnir/Mjolnir.xcodeproj -scheme Mjolnir -configuration Debug build
```

## Architecture

### Key Decisions
- **Windows:** SwiftUI `WindowGroup` for multi-window management; AppKit `NSSplitViewController` for the 3-panel internal layout
- **AI Backend:** Claude CLI subprocess (`claude -p --output-format stream-json`) — leverages user's existing `claude login` session
- **Terminal:** SwiftTerm `LocalProcessTerminalView` (SPM: `https://github.com/migueldeicaza/SwiftTerm` v1.11.0+)
- **Git Worktrees:** Opt-in per chat. Regular chats work on the current branch; worktree chats get isolated `.mjolnir/worktrees/<chatId>/` directories
- **Persistence:** SwiftData with CloudKit one-way backup
- **Sandbox:** Disabled (Hardened Runtime instead) — CLI subprocess + terminal need full shell access

### Concurrency
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (Xcode 26 default)
- Views/ViewModels: implicitly `@MainActor`
- Services: must be `actor` types (`ClaudeCLIService`, `GitService`, `GitWorktreeManager`, `FileSystemService`)
- Cross-actor communication via `await`

### External Dependencies
| Package | URL | Version | Purpose |
|---------|-----|---------|---------|
| SwiftTerm | `https://github.com/migueldeicaza/SwiftTerm` | 1.11.0+ | Fully interactive embedded terminal |

---

## Implementation Plan

### Directory Structure
```
Mjolnir/
  MjolnirApp.swift
  Mjolnir.entitlements
  AppState.swift

  Models/
    Project.swift, Chat.swift, Message.swift, ToolCall.swift, UserSettings.swift

  Services/
    Claude/
      ClaudeCLIService.swift, CLIMessageTypes.swift, CLISessionManager.swift
    Git/
      GitService.swift, GitWorktreeManager.swift
    FileSystem/
      FileSystemService.swift
    CloudKit/
      CloudKitBackupService.swift

  ViewModels/
    SidebarViewModel.swift, ChatViewModel.swift
    InspectorViewModel.swift, ToolbarViewModel.swift

  Views/
    Window/
      MainSplitViewController.swift, WindowRepresentable.swift
    Sidebar/
      SidebarViewController.swift, ProjectRowView.swift, ChatRowView.swift
    Chat/
      ChatViewController.swift, MessageCellView.swift, MarkdownRenderer.swift
      ChatInputView.swift, ModelSelectorView.swift
    Inspector/
      InspectorViewController.swift, FileTreeViewController.swift
      ModifiedFilesViewController.swift, DiffViewController.swift
    Toolbar/
      ToolbarView.swift, TerminalPanelView.swift, OpenMenuController.swift
    Settings/
      SettingsView.swift
    Shared/
      ContextUsageView.swift, GitBranchView.swift
```

---

### Phase 1: Foundation — Data Models, Entitlements, App Shell

- [x] Create `Mjolnir.entitlements` (disable sandbox, hardened runtime)
- [x] Update build settings: `ENABLE_APP_SANDBOX = NO`, `ENABLE_HARDENED_RUNTIME = YES`
- [x] Create `Models/Project.swift` — `@Model` with name, path, sortOrder, isExpanded, runCommand, systemPrompt; cascade relationship to `[Chat]`
- [x] Create `Models/Chat.swift` — `@Model` with title, sortOrder, sessionID, branchName, worktreePath, baseBranch, hasWorktree; `workingDirectory` computed property
- [x] Create `Models/Message.swift` — `@Model` with role, content, isStreaming, stopReason, inputTokens, outputTokens, modelID; cascade relationship to `[ToolCall]`
- [x] Create `Models/ToolCall.swift` — `@Model` with toolUseID, toolName, inputJSON, outputJSON, status
- [x] Create `Models/UserSettings.swift` — `@Model` with defaultModel, theme, maxTokens
- [x] Update `MjolnirApp.swift` — new ModelContainer schema, placeholder `MainWindowView`, Settings scene
- [x] Delete `Item.swift` and `ContentView.swift`
- [x] Verify: app builds, launches, SwiftData container initializes

---

### Phase 2: AppKit Window Shell — NSSplitViewController in SwiftUI

- [x] Create `AppState.swift` — `@Observable` class: selectedProject, selectedChat, isSidebarVisible, isInspectorVisible
- [x] Create `Views/Window/MainSplitViewController.swift` — `NSSplitViewController` with 3 `NSSplitViewItem`s (sidebar: collapsible, min 220pt; content: min 400pt; inspector: collapsible, initially collapsed)
- [x] Create `Views/Window/WindowRepresentable.swift` — `NSViewControllerRepresentable` bridging ModelContext + AppState into AppKit
- [x] Create placeholder `SidebarViewController`, `ChatViewController`, `InspectorViewController`
- [x] Configure window: `titlebarAppearsTransparent`, `titleVisibility = .hidden`, `fullSizeContentView`
- [x] Verify: 3-panel split visible, panels collapse/expand, Cmd+N opens new window, custom titlebar

---

### Phase 3: Claude CLI Integration Service

- [x] Create `Services/Claude/CLIMessageTypes.swift` — Comprehensive Codable types matching TypeScript SDK: `CLIMessage` (system/assistant/user/result/streamEvent/toolProgress/toolUseSummary/authStatus/rateLimit), all system subtypes (init/compact_boundary/status/hooks/tasks), `ContentBlock` (text/thinking/toolUse/serverToolUse/mcp/compaction), stream events, usage types
- [x] Create `Services/Claude/ClaudeCLIService.swift` — `actor`: findClaudeBinary(), sendMessage(prompt, model, workingDirectory, sessionID, ...) → AsyncThrowingStream<CLIMessage>, cancel()
- [x] Implement subprocess spawning: `Process` with `claude -p --output-format stream-json --verbose`, stdout pipe, line-by-line JSON decoding, CLAUDECODE env stripped
- [x] Create `Services/Claude/CLISessionManager.swift` — session ID extraction from init message, resume flag, fork session
- [x] Add CLI availability check: `isClaudeInstalled()`, `isClaudeLoggedIn()`
- [ ] Verify: spawn `claude -p "hello" --output-format stream-json`, parse streaming output, extract session ID, cancel mid-stream

---

### Phase 4: Sidebar — Project and Chat Management

- [ ] Create `Services/Git/GitWorktreeManager.swift` — `actor`: createWorktree(), removeWorktree(), listWorktrees(), reconcile(), ensureGitignore()
- [ ] Create `ViewModels/SidebarViewModel.swift` — `@Observable`: projects, selectedProject, selectedChat, createProject(), createChat() (regular), createWorktreeChat() (isolated), deleteChat(), reorder
- [ ] Create `Views/Sidebar/SidebarViewController.swift` — `NSOutlineViewDelegate` + `NSOutlineViewDataSource`, hierarchical projects→chats, drag-and-drop
- [ ] Create `Views/Sidebar/ProjectRowView.swift` — folder icon + name + count badge + chevron + context menu
- [ ] Create `Views/Sidebar/ChatRowView.swift` — chat icon + title + branch indicator (for worktree chats) + context menu
- [ ] Implement new project flow: "+" → NSOpenPanel → create Project + ensureGitignore
- [ ] Implement new regular chat flow: creates Chat with hasWorktree=false
- [ ] Implement new worktree chat flow: creates Chat with hasWorktree=true + GitWorktreeManager.createWorktree()
- [ ] Implement delete chat: if hasWorktree, remove worktree + branch
- [ ] Verify: create project, create regular chat, create worktree chat (worktree created), delete worktree chat (cleaned up), drag-and-drop reorder, collapse/expand

---

### Phase 5: Chat Interface — Messages, Input, and Streaming

- [ ] Create `ViewModels/ChatViewModel.swift` — `@Observable`: messages, currentStreamText, isProcessing, selectedModel, inputText, contextUsagePercent, currentBranch
- [ ] Implement `sendMessage()`: create user Message, create streaming assistant Message, call ClaudeCLIService, handle CLIMessage stream (system/assistant/result), persist to SwiftData
- [ ] Implement `cancelGeneration()`: call ClaudeCLIService.cancel()
- [ ] Create `Views/Chat/ChatViewController.swift` — layout: ToolbarView + NSScrollView message list + TerminalPanel (collapsible) + ChatInputView + data row (branch + context)
- [ ] Create `Views/Chat/MessageCellView.swift` — user (right-aligned, accent bg), assistant (left-aligned, markdown), tool use (collapsible), streaming indicator
- [ ] Create `Views/Chat/MarkdownRenderer.swift` — `NSAttributedString(markdown:)` + custom code block rendering (monospace, gray bg)
- [ ] Create `Views/Chat/ChatInputView.swift` — auto-growing NSTextView, Enter=send / Shift+Enter=newline, send button, dictation button placeholder
- [ ] Create `Views/Chat/ModelSelectorView.swift` — NSPopUpButton with Claude models (sonnet, opus, haiku)
- [ ] Create `Views/Toolbar/ToolbarView.swift` — thread name (editable), Run/Open/Terminal/Inspector toggle buttons
- [ ] Create `Views/Shared/ContextUsageView.swift` — circular arc (green→yellow→red) from token usage
- [ ] Create `Views/Shared/GitBranchView.swift` — branch icon + name label
- [ ] Verify: send message → streaming response, markdown renders, tool calls displayed, model selector works, context usage updates, branch displays, cancel works

---

### Phase 6: Inspector — File Tree and Git Integration

- [ ] Create `Services/Git/GitService.swift` — `actor`: currentBranch(), status() → [GitFileStatus], diff(), commit(), discardChanges(), all scoped to a working directory path
- [ ] Create `Services/FileSystem/FileSystemService.swift` — `actor`: buildFileTree(), startWatching() (FSEvents), stopWatching()
- [ ] Create `ViewModels/InspectorViewModel.swift` — `@Observable`: fileTree, modifiedFiles, selectedTab (.files/.modified), refresh(), commitFiles(), discardFiles() — operates on chat.workingDirectory
- [ ] Create `Views/Inspector/InspectorView.swift` — SwiftUI segmented Picker switching Files/Modified tabs, inline commit/discard UI
- [ ] Create `Views/Inspector/FileTreeView.swift` — SwiftUI recursive file tree with expand/collapse, file-type icons
- [ ] Create `Views/Inspector/ModifiedFilesView.swift` — SwiftUI list with colored A/M/D status labels, file name + directory path, tap to view diff
- [ ] Create `Views/Inspector/DiffViewController.swift` — new window, side-by-side (old vs current), highlighted additions/deletions, synchronized scrolling, line numbers
- [ ] Verify: file tree shows directory, modified tab shows git status (scoped to worktree for worktree chats), diff view works, commit creates git commit, discard reverts files, tree refreshes on changes

---

### Phase 7: Terminal Integration (SwiftTerm) and Run Command

- [ ] Add SwiftTerm SPM dependency: `https://github.com/migueldeicaza/SwiftTerm` v1.11.0+
- [ ] Create `Views/Toolbar/TerminalPanelView.swift` — wraps `LocalProcessTerminalView`, starts shell in chat.workingDirectory, handles processTerminated/sizeChanged/setTerminalTitle
- [ ] Integrate terminal as collapsible panel in ChatViewController (animated 0↔200pt height)
- [ ] Terminal starts in `chat.workingDirectory` (worktree path for worktree chats, project path for regular)
- [ ] Create `Views/Toolbar/OpenMenuController.swift` — NSMenu: Reveal in Finder, Open in Xcode/VS Code/Terminal (detect installed apps)
- [ ] Implement Run button: executes `project.runCommand` in terminal, configurable via sheet if not set
- [ ] Verify: terminal opens with full interactivity (vim, htop, git works), colors + cursor correct, Run button executes command, Open menu detects IDEs

---

### Phase 8: Settings and Preferences

- [ ] Create `Views/Settings/SettingsView.swift` — TabView: General + Claude CLI status
- [ ] Create General tab: default model picker, theme selector
- [ ] Create CLI Status tab: show installed/not found, login status, install instructions link, login button
- [ ] Verify: Settings opens via Cmd+,, CLI status correct, default model persists

---

### Phase 9: Advanced Features

#### 9A: CloudKit Backup
- [ ] Create `Services/CloudKit/CloudKitBackupService.swift` — one-way push to privateCloudDatabase, restore on demand
- [ ] Add CloudKit entitlements
- [ ] Verify: backup visible in CloudKit Dashboard, restore recreates data

#### 9B: Dictation
- [ ] Create `DictationService.swift` — `SFSpeechRecognizer` for real-time speech-to-text
- [ ] Wire dictation button in ChatInputView
- [ ] Add microphone + speech recognition usage descriptions
- [ ] Verify: dictation captures speech into input box

#### 9C: Worktree Actions
- [ ] "Apply to main" context menu action: merge worktree branch into base
- [ ] "Update from main" action: rebase/merge base into worktree branch
- [ ] "Create PR" action: push worktree branch, open GitHub PR creation
- [ ] "Convert to worktree" action on regular chats
- [ ] Verify: merge/rebase actions work, PR creation opens browser

---

## Phase Dependencies

```
Phase 1 (Foundation)
  ├──→ Phase 2 (Window Shell)
  │      └──→ Phase 4 (Sidebar + Worktrees) ──→ Phase 5 (Chat Interface)
  │                    │                              │
  │                    └──→ Phase 6 (Inspector)       ├──→ Phase 7 (Terminal)
  │                                                   └──→ Phase 8 (Settings)
  └──→ Phase 3 (Claude CLI Service) ──────────────────────→ Phase 5
                                                              │
                                                              └──→ Phase 9 (Advanced)
```

Parallel tracks after Phase 1:
- **Track A (UI):** 2 → 4 → 5 → 7
- **Track B (Backend):** 3 (Claude CLI)
- **Track C (Inspector):** 6 (after 4)
- **Convergence:** Phase 5 merges Track A + B
