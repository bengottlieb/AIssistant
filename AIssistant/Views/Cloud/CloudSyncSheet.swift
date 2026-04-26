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
	@State private var downloadSuccess = false

	private var status: CloudStatusCache.SyncStatus {
		cloudCache.syncStatus(for: item)
	}

	private var contentMatchesCloud: Bool {
		let localContent = (try? String(contentsOf: item.sourceURL, encoding: .utf8)) ?? item.rawContent
		return cloudCache.cloudContent(for: item) == localContent
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

			if downloadSuccess {
				Label("Download complete!", systemImage: "checkmark.circle.fill")
					.foregroundStyle(.green)
			}

			HStack {
				Button("Close") { dismiss() }
					.keyboardShortcut(.cancelAction)

				if status != .notBacked {
					Button("Compare") { showingPreview = true }
						.disabled(contentMatchesCloud)
				}

				if status == .cloudNewer {
					Button("Download from Cloud") {
						performDownload()
					}
					.keyboardShortcut(.defaultAction)
					.disabled(downloadSuccess)
				}

				if status != .cloudNewer {
					Button(status == .notBacked ? "Upload" : "Update") {
						performUpload()
					}
					.keyboardShortcut(status == .cloudNewer ? nil : .defaultAction)
					.disabled(uploadSuccess || (status != .notBacked && contentMatchesCloud))
				}
			}
		}
		.padding(24)
		.frame(minWidth: 400)
		.sheet(isPresented: $showingPreview) {
			CloudPreviewSheet(item: item) { dismiss() }
		}
	}

	private var statusText: String {
		switch status {
		case .checking: "Checking…"
		case .notBacked: "Not backed up"
		case .synced: "Synced"
		case .localNewer: "Local changes not yet uploaded"
		case .cloudNewer: "iCloud has a newer version"
		}
	}

	private func performUpload() {
		uploadError = nil
		CloudSyncService.shared.upload(item)
		uploadSuccess = true
		cloudCache.localFileDidChange()
	}

	private func performDownload() {
		uploadError = nil
		guard let cloudContent = cloudCache.cloudContent(for: item) else {
			uploadError = "Unable to retrieve cloud content"
			return
		}
		do {
			try cloudContent.write(to: item.sourceURL, atomically: true, encoding: .utf8)
			NotificationCenter.default.post(name: .cloudReplacedLocalFile, object: item.sourceURL, userInfo: ["content": cloudContent])
			downloadSuccess = true
			cloudCache.localFileDidChange()
		} catch {
			uploadError = "Failed to write file: \(error.localizedDescription)"
		}
	}
}
