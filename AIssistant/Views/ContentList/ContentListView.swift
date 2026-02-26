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
		.task(id: TaskID(platform: platform, category: category)) {
			await scanItems()
		}
	}

	private func scanItems() async {
		loadingState = .loading
		let scanner = platform.scanner(for: category)

		let result: [ContentItem]? = await report("Scanning \(platform.displayName) \(category.displayName)") {
			try await scanner.scan()
		}

		if let items = result {
			loadingState = items.isEmpty ? .empty : .loaded(items)
		} else {
			loadingState = .empty
		}
	}

	private struct TaskID: Equatable {
		let platform: PlatformKind
		let category: ContentCategoryKind
	}
}
