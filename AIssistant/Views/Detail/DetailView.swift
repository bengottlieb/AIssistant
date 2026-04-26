//
//  DetailView.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import Internal

struct DetailView: View {
	let item: ContentItem

	@State private var editedContent: String = ""
	@State private var showingTransferSheet = false
	@State private var showingCloudSheet = false
	@State private var saveTask: Task<Void, Never>?
	@State private var pendingSaveURL: URL?
	@State private var jsonValidationError: String?
	@Environment(CloudStatusCache.self) private var cloudCache

	var body: some View {
		VStack(spacing: 0) {
			MetadataView(item: item)
				.padding()

			CloudDifferenceBanner(item: item, showCloudSheet: $showingCloudSheet)

			Divider()

			VStack(spacing: 0) {
				HSplitView {
					MarkdownEditorView(content: $editedContent)
						.id(item.sourceURL)
						.onChange(of: editedContent) { _, newValue in
							scheduleAutoSave(content: newValue)
							validateJSON(content: newValue)
						}

					if item.isMarkdown {
						MarkdownPreviewView(markdown: editedContent)
					}
				}

				if let error = jsonValidationError {
					JSONValidationBanner(error: error)
				}
			}
		}
		.navigationTitle(item.name)
		.toolbar {
			ToolbarItemGroup {
				CloudToolbarButton(item: item)

				Button {
					showingTransferSheet = true
				} label: {
					Label("Transfer", systemImage: "arrow.right.arrow.left")
				}
			}
		}
		.sheet(isPresented: $showingTransferSheet) {
			TransferSheet(item: item)
		}
		.sheet(isPresented: $showingCloudSheet) {
			CloudSyncSheet(item: item)
		}
		.onAppear {
			editedContent = item.rawContent
			validateJSON(content: item.rawContent)
		}
		.onChange(of: item) { oldItem, newItem in
			flushPendingSave(for: oldItem)
			editedContent = newItem.rawContent
			validateJSON(content: newItem.rawContent)
		}
		.onReceive(NotificationCenter.default.publisher(for: .cloudReplacedLocalFile)) { notification in
			guard let url = notification.object as? URL,
				  url == item.sourceURL,
				  let content = notification.userInfo?["content"] as? String else { return }
			editedContent = content
			validateJSON(content: content)
		}
	}

	private func scheduleAutoSave(content: String) {
		guard content != item.rawContent else {
			saveTask?.cancel()
			pendingSaveURL = nil
			return
		}
		saveTask?.cancel()
		let url = item.sourceURL
		pendingSaveURL = url
		saveTask = Task {
			try? await Task.sleep(for: .milliseconds(500))
			guard !Task.isCancelled else { return }
			try? content.write(to: url, atomically: true, encoding: .utf8)
			pendingSaveURL = nil
			await MainActor.run { cloudCache.localFileDidChange() }
		}
	}

	private func flushPendingSave(for oldItem: ContentItem) {
		saveTask?.cancel()
		if pendingSaveURL != nil, editedContent != oldItem.rawContent {
			try? editedContent.write(to: oldItem.sourceURL, atomically: true, encoding: .utf8)
		}
		pendingSaveURL = nil
	}

	private func validateJSON(content: String) {
		guard item.isJSON else {
			jsonValidationError = nil
			return
		}

		guard let data = content.data(using: .utf8) else {
			jsonValidationError = "Unable to encode content as UTF-8"
			return
		}

		do {
			_ = try JSONSerialization.jsonObject(with: data)
			jsonValidationError = nil
		} catch {
			jsonValidationError = error.localizedDescription
		}
	}
}

private struct JSONValidationBanner: View {
	let error: String

	var body: some View {
		HStack(spacing: 8) {
			Image(systemName: "exclamationmark.triangle.fill")
				.foregroundStyle(.yellow)
			Text("Invalid JSON: \(error)")
				.font(.system(.caption, design: .monospaced))
				.foregroundStyle(.primary)
			Spacer()
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 8)
		.background(Color(nsColor: .controlBackgroundColor))
		.overlay(alignment: .top) {
			Divider()
		}
	}
}

private struct CloudDifferenceBanner: View {
	let item: ContentItem
	@Binding var showCloudSheet: Bool
	@Environment(CloudStatusCache.self) private var cloudCache

	var body: some View {
		let status = cloudCache.syncStatus(for: item)
		if !item.isRemoteOnly, status == .localNewer || status == .cloudNewer {
			HStack(spacing: 8) {
				Image(systemName: "icloud.fill")
					.foregroundStyle(status == .cloudNewer ? .yellow : .orange)
				Text(message(for: status))
					.font(.subheadline)
				Spacer()
				Button("Compare") { showCloudSheet = true }
					.buttonStyle(.borderless)
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 6)
			.background(Color(nsColor: .controlBackgroundColor))
		}
	}

	private func message(for status: CloudStatusCache.SyncStatus) -> String {
		switch status {
		case .cloudNewer: "Cloud version is newer than local."
		case .localNewer: "Local version is newer than cloud."
		default: ""
		}
	}
}
