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
	@State private var saveTask: Task<Void, Never>?
	@State private var pendingSaveURL: URL?

	var body: some View {
		VStack(spacing: 0) {
			MetadataView(item: item)
				.padding()

			Divider()

			HSplitView {
				MarkdownEditorView(content: $editedContent)
					.onChange(of: editedContent) { _, newValue in
						scheduleAutoSave(content: newValue)
					}

				MarkdownPreviewView(markdown: editedContent)
			}
		}
		.navigationTitle(item.name)
		.toolbar {
			ToolbarItemGroup {
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
		.onAppear {
			editedContent = item.rawContent
		}
		.onChange(of: item) { oldItem, newItem in
			flushPendingSave(for: oldItem)
			editedContent = newItem.rawContent
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
		}
	}

	private func flushPendingSave(for oldItem: ContentItem) {
		saveTask?.cancel()
		if pendingSaveURL != nil, editedContent != oldItem.rawContent {
			try? editedContent.write(to: oldItem.sourceURL, atomically: true, encoding: .utf8)
		}
		pendingSaveURL = nil
	}
}
