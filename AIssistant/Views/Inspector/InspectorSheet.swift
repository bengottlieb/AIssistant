//
//  InspectorSheet.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 6/28/26.
//

import SwiftUI
import AppKit
import Internal

struct InspectorSheet: View {
	let item: ContentItem

	@Environment(\.dismiss) private var dismiss
	@Environment(CloudStatusCache.self) private var cloudCache

	@State private var entries: [BundleEntry] = []
	@State private var status: CloudStatusCache.SyncStatus = .checking
	@State private var cloudModifiedAt: Date?

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			header
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					InspectorOverview(item: item, entries: entries, status: status, cloudModifiedAt: cloudModifiedAt)
					InspectorFileList(entries: entries)
				}
			}
			HStack {
				Button("Close") { dismiss() }
					.keyboardShortcut(.cancelAction)
				Spacer()
				Button("Refresh") { Task { await cloudCache.refresh(); load() } }
				if !item.isRemoteOnly {
					Button("Reveal in Finder") {
						NSWorkspace.shared.activateFileViewerSelecting([item.sourceURL])
					}
				}
			}
		}
		.padding(20)
		.frame(minWidth: 540, minHeight: 500)
		.task { load() }
	}

	private var header: some View {
		VStack(alignment: .leading, spacing: 4) {
			HStack {
				Image(systemName: item.category.systemImage)
					.foregroundStyle(.tint)
				Text(item.name)
					.font(.title2.bold())
			}
			if let description = item.itemDescription {
				Text(description)
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	@MainActor
	private func load() {
		let cloudFile = CloudSyncService.shared.cachedCloudFile(forRecordName: item.cloudRecordName)
		status = cloudCache.syncStatus(for: item)
		cloudModifiedAt = cloudFile?.modifiedAt
		entries = BundleInspector.entries(for: item, cloudFile: cloudFile)
	}
}
