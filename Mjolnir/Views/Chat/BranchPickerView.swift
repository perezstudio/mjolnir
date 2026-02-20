import SwiftUI

struct BranchPickerView: View {
    let workingDirectory: String
    @Binding var currentBranch: String
    @Environment(\.dismiss) private var dismiss

    @State private var branches: [String] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let gitService = GitService.shared

    private var filteredBranches: [String] {
        if searchText.isEmpty {
            return branches
        }
        return branches.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            branchList
        }
        .frame(width: 260, height: 300)
        .task {
            await loadBranches()
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Filter branches...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(8)
    }

    // MARK: - Branch List

    private var branchList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.secondary)
                        .padding()
                } else if filteredBranches.isEmpty {
                    Text("No matching branches")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(filteredBranches, id: \.self) { branch in
                        branchRow(branch)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func branchRow(_ branch: String) -> some View {
        Button {
            switchToBranch(branch)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: branch == currentBranch ? "checkmark" : "")
                    .frame(width: 16)
                    .foregroundStyle(Color.accentColor)

                Text(branch)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func loadBranches() async {
        do {
            let result = try await gitService.listBranches(at: workingDirectory)
            let current = try await gitService.currentBranch(at: workingDirectory)
            branches = result
            currentBranch = current
            isLoading = false
        } catch {
            errorMessage = "Failed to load branches"
            isLoading = false
        }
    }

    private func switchToBranch(_ branch: String) {
        guard branch != currentBranch else {
            dismiss()
            return
        }
        Task {
            do {
                try await gitService.switchBranch(branch, at: workingDirectory)
                currentBranch = branch
                dismiss()
            } catch {
                errorMessage = "Failed to switch to \(branch)"
            }
        }
    }
}
