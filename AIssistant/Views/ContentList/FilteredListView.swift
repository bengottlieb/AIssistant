//
//  FilteredListView.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 6/24/26.
//

import SwiftUI
import Internal
import Chronicle

struct FilteredListView: View {
	let platform: PlatformKind
	let filterText: String

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
				EmptyStateView(message: "No items found", systemImage: "magnifyingglass")

			case .failed(let error):
				EmptyStateView(message: error.localizedDescription, systemImage: "exclamationmark.triangle")

			case .loaded(let items):
				let matches = items.filter { $0.name.localizedCaseInsensitiveContains(filterText) }
				if matches.isEmpty {
					EmptyStateView(message: "No items matching “\(filterText)”", systemImage: "magnifyingglass")
				} else {
					resultsList(matches)
				}
			}
		}
		.navigationTitle("Filter: \(filterText)")
		.task(id: TaskID(platform: platform, refreshID: refreshID)) { await scanAll() }
		.onAppear { startWatching() }
		.onChange(of: platform) { startWatching() }
		.onReceive(NotificationCenter.default.publisher(for: .skillInstallStateChanged)) { _ in
			startWatching()
			refreshID = UUID()
		}
	}

	private func resultsList(_ matches: [ContentItem]) -> some View {
		let binding = Binding(
			get: { viewModel.selectedItem },
			set: { viewModel.selectedItem = $0 }
		)
		return List(selection: binding) {
			ForEach(ContentCategoryKind.sidebarCategories) { category in
				let categoryItems = matches.filter { $0.category == category }
				if !categoryItems.isEmpty {
					Section(category.displayName) {
						ForEach(categoryItems) { item in
							ContentItemRow(item: item).tag(item)
						}
					}
				}
			}
		}
	}

	private func scanAll() async {
		loadingState = .loading
		let categories = ContentCategoryKind.sidebarCategories
		var all: [ContentItem] = []

		await withTaskGroup(of: [ContentItem].self) { group in
			for category in categories {
				let scanner = platform.scanner(for: category)
				group.addTask {
					do {
						return try await scanner.scan()
					} catch {
						Chronicle.error(error, description: "Filter scan failed for \(category.displayName)")
						return []
					}
				}
			}
			for await items in group { all.append(contentsOf: items) }
		}

		guard !Task.isCancelled else { return }
		let sorted = all.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
		loadingState = sorted.isEmpty ? .empty : .loaded(sorted)
	}

	private func startWatching() {
		let directories = Array(Set(ContentCategoryKind.sidebarCategories
			.flatMap { platform.scanner(for: $0).watchedDirectories }))
		guard !directories.isEmpty else { watcher = nil; return }

		watcher = DirectoryWatcher(directories: directories) { [self] in refreshID = UUID() }
	}

	private struct TaskID: Equatable {
		let platform: PlatformKind
		let refreshID: UUID
	}
}
