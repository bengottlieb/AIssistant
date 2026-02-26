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
	@State private var showingPreview = false
	@State private var showingTransferSheet = false
	@State private var hasChanges = false

	var body: some View {
		VStack(spacing: 0) {
			if let document = item.document, !document.frontmatter.fields.isEmpty {
				MetadataView(frontmatter: document.frontmatter)
					.padding()

				Divider()
			}

			// Editor / Preview toggle
			Group {
				if showingPreview {
					MarkdownPreviewView(markdown: editedContent)
				} else {
					MarkdownEditorView(content: $editedContent)
						.onChange(of: editedContent) { _, newValue in
							hasChanges = newValue != item.rawContent
						}
				}
			}
		}
		.navigationTitle(item.name)
		.toolbar {
			ToolbarItemGroup {
				Picker("Mode", selection: $showingPreview) {
					Label("Edit", systemImage: "pencil")
						.tag(false)
					Label("Preview", systemImage: "eye")
						.tag(true)
				}
				.pickerStyle(.segmented)

				Button {
					showingTransferSheet = true
				} label: {
					Label("Transfer", systemImage: "arrow.right.arrow.left")
				}

				if hasChanges {
					Button("Save") {
						saveContent()
					}
					.keyboardShortcut("s", modifiers: .command)
				}
			}
		}
		.sheet(isPresented: $showingTransferSheet) {
			TransferSheet(item: item)
		}
		.onAppear {
			editedContent = item.rawContent
			hasChanges = false
		}
		.onChange(of: item) { _, newItem in
			editedContent = newItem.rawContent
			hasChanges = false
		}
	}

	private func saveContent() {
		let content = editedContent
		let url = item.sourceURL
		let name = item.name
		report("Saving \(name)") {
			try content.write(to: url, atomically: true, encoding: .utf8)
		}
		hasChanges = false
	}
}
