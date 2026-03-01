//
//  CloudSyncSheet.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 3/1/26.
//

import SwiftUI
import Internal

struct CloudSyncSheet: View {
	let item: ContentItem

	@Environment(\.dismiss) private var dismiss
	@Environment(CloudStatusCache.self) private var cloudCache
	@State private var showingPreview = false
	@State private var uploadError: String?
	@State private var uploadSuccess = false

	private var status: CloudStatusCache.SyncStatus {
		cloudCache.syncStatus(for: item)
	}

	private var contentMatchesCloud: Bool {
		cloudCache.cloudContent(for: item) == item.rawContent
	}

	var body: some View {
		VStack(spacing: 20) {
			Text("Cloud Sync: \"\(item.name)\"")
				.font(.headline)

			GroupBox("Details") {
				VStack(alignment: .leading, spacing: 8) {
					LabeledContent("Platform", value: item.platformKind.displayName)
					LabeledContent("Category", value: item.category.displayName)
					LabeledContent("Status", value: statusText)
					LabeledContent("Record Name") {
						Text(item.cloudRecordName)
							.font(.system(.caption, design: .monospaced))
							.textSelection(.enabled)
					}
				}
				.frame(maxWidth: .infinity, alignment: .leading)
			}

			if let error = uploadError {
				Text(error)
					.font(.caption)
					.foregroundStyle(.red)
			}

			if uploadSuccess {
				Label("Upload complete!", systemImage: "checkmark.circle.fill")
					.foregroundStyle(.green)
			}

			HStack {
				Button("Close") { dismiss() }
					.keyboardShortcut(.cancelAction)

				if status != .notBacked {
					Button("Compare") { showingPreview = true }
						.disabled(contentMatchesCloud)
				}

				Button(status == .notBacked ? "Upload" : "Update") {
					performUpload()
				}
				.keyboardShortcut(.defaultAction)
				.disabled(uploadSuccess || (status != .notBacked && contentMatchesCloud))
			}
		}
		.padding(24)
		.frame(minWidth: 400)
		.sheet(isPresented: $showingPreview) {
			CloudPreviewSheet(item: item)
		}
	}

	private var statusText: String {
		switch status {
		case .notBacked: "Not backed up"
		case .synced: "Synced"
		case .pending: "Pending sync"
		}
	}

	private func performUpload() {
		uploadError = nil
		CloudSyncService.shared.upload(item)
		uploadSuccess = true
	}
}
