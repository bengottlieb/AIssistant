//
//  ContentListView.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import Internal
import Chronicle

struct ContentListView: View {
	let platform: PlatformKind
	let category: ContentCategoryKind

	@Environment(AppViewModel.self) private var viewModel
	@Environment(CloudStatusCache.self) private var cloudCache
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
				let binding = Binding(
					get: { viewModel.selectedItem },
					set: { viewModel.selectedItem = $0 }
				)
				let remoteOnly = items.filter { $0.isRemoteOnly }
				let local = items.filter { !$0.isRemoteOnly }
				if category.usesSections {
					let installed = local.filter { $0.isInstalled }
					let others = local.filter { !$0.isInstalled }
					List(selection: binding) {
						if !installed.isEmpty {
							Section("Installed") {
								ForEach(installed) { item in ContentItemRow(item: item, onDownload: download).tag(item) }
							}
						}
						if !others.isEmpty {
							Section("Available") {
								ForEach(others) { item in ContentItemRow(item: item, onDownload: download).tag(item) }
							}
						}
						if !remoteOnly.isEmpty {
							Section("Cloud Only") {
								ForEach(remoteOnly) { item in ContentItemRow(item: item, onDownload: download).tag(item) }
							}
						}
					}
				} else {
					List(selection: binding) {
						ForEach(local) { item in ContentItemRow(item: item, onDownload: download).tag(item) }
						if !remoteOnly.isEmpty {
							Section("Cloud Only") {
								ForEach(remoteOnly) { item in ContentItemRow(item: item, onDownload: download).tag(item) }
							}
						}
					}
				}
			}
		}
		.navigationTitle(category.displayName)
		.task(id: TaskID(platform: platform, category: category, refreshID: refreshID, hasRefreshed: cloudCache.hasRefreshed)) {
			await scanItems()
		}
		.onAppear { startWatching() }
		.onChange(of: platform) { startWatching() }
		.onChange(of: category) { startWatching() }
		.onReceive(NotificationCenter.default.publisher(for: .skillInstallStateChanged)) { _ in
			startWatching()
			refreshID = UUID()
		}
	}

	private func scanItems() async {
		if category == .sharedClaudeMD {
			let item = ContentItem.loadSharedClaudeMD()
			loadingState = .loaded([item])
			viewModel.selectedItem = item
			return
		}

		loadingState = .loading
		let scanner = platform.scanner(for: category)
        var result: [ContentItem]?
        do {
            result = try await scanner.scan()
        } catch {
            Chronicle.error(error, description: "Failed to scan \(platform.displayName) \(category.displayName)")
        }

		let localItems = result ?? []
		let merged = mergeWithCloudOnly(localItems: localItems)

		if merged.isEmpty {
			loadingState = .empty
		} else {
			loadingState = .loaded(merged)
			if let url = viewModel.pendingSelectionURL, let match = merged.first(where: { $0.id == url }) {
				viewModel.selectedItem = match
				viewModel.pendingSelectionURL = nil
			}
		}
	}

	private func mergeWithCloudOnly(localItems: [ContentItem]) -> [ContentItem] {
		let sortedLocal = localItems.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
		guard category != .sharedClaudeMD else { return sortedLocal }

		let localPaths = Set(localItems.map { $0.cloudRelativePath })
		let cloudFiles = CloudSyncService.shared.cachedCloudFiles(platform: platform, category: category)
		let cloudOnly = cloudFiles
			.filter { !localPaths.contains($0.relativePath) }
			.compactMap { ContentItem.remoteOnly(from: $0) }
			.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

		return sortedLocal + cloudOnly
	}

	private func download(_ item: ContentItem) {
		guard item.isRemoteOnly,
			  let file = CloudSyncService.shared.cachedCloudFile(forRecordName: item.cloudRecordName) else { return }
		guard CloudSyncFileWriter.writeToLocalDisk(file) else { return }
		viewModel.pendingSelectionURL = item.sourceURL
		refreshID = UUID()
	}

	private func startWatching() {
		if category == .sharedClaudeMD {
			let homeDir = ContentItem.sharedClaudeMDURL.deletingLastPathComponent()
			watcher = DirectoryWatcher(directories: [homeDir]) { [self] in
				refreshID = UUID()
			}
			return
		}

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
		let hasRefreshed: Bool
	}
}
