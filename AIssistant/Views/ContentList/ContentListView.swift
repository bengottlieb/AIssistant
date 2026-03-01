//
//  ContentListView.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import Internal

struct ContentListView: View {
	let platform: PlatformKind
	let category: ContentCategoryKind

	@Environment(AppViewModel.self) private var viewModel
	@State private var loadingState: LoadingState<[ContentItem]> = .idle
	@State private var watcher: DirectoryWatcher?
	@State private var refreshID = UUID()

	var body: some View {
		Group {
			switch loadingState {
			case .idle, .loading:
				ProgressView("Scanning…")
					.frame(maxWidth: .infinity, maxHeight: .infinity)

			case .empty:
				EmptyStateView(
					message: "No \(category.displayName.lowercased()) found",
					systemImage: category.systemImage
				)

			case .failed(let error):
				VStack(spacing: 12) {
					Image(systemName: "exclamationmark.triangle")
						.font(.largeTitle)
						.foregroundStyle(.secondary)
					Text("Failed to scan")
						.font(.headline)
					Text(error.localizedDescription)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)

			case .loaded(let items):
				List(items, selection: Binding(
					get: { viewModel.selectedItem },
					set: { viewModel.selectedItem = $0 }
				)) { item in
					ContentItemRow(item: item)
						.tag(item)
				}
			}
		}
		.navigationTitle(category.displayName)
		.task(id: TaskID(platform: platform, category: category, refreshID: refreshID)) {
			await scanItems()
		}
		.onAppear { startWatching() }
		.onChange(of: platform) { startWatching() }
		.onChange(of: category) { startWatching() }
	}

	private func scanItems() async {
		loadingState = .loading
		let scanner = platform.scanner(for: category)

		let result: [ContentItem]? = await report("Scanning \(platform.displayName) \(category.displayName)") {
			try await scanner.scan()
		}

		if let items = result {
			let sorted = items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
			loadingState = sorted.isEmpty ? .empty : .loaded(sorted)
			if let url = viewModel.pendingSelectionURL, let match = sorted.first(where: { $0.id == url }) {
				viewModel.selectedItem = match
				viewModel.pendingSelectionURL = nil
			}
		} else {
			loadingState = .empty
		}
	}

	private func startWatching() {
		let scanner = platform.scanner(for: category)
		let directories = scanner.watchedDirectories
		guard !directories.isEmpty else { watcher = nil; return }

		watcher = DirectoryWatcher(directories: directories) { [self] in
			refreshID = UUID()
		}
	}

	private struct TaskID: Equatable {
		let platform: PlatformKind
		let category: ContentCategoryKind
		let refreshID: UUID
	}
}
