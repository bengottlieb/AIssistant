//
//  MetadataView.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import Internal

struct MetadataView: View {
	let item: ContentItem
	@State private var isExpanded = false

	var body: some View {
		Button {
			withAnimation { isExpanded.toggle() }
		} label: {
			if isExpanded {
				expandedContent
			} else {
				collapsedContent
			}
		}
		.buttonStyle(.plain)
	}

	private var collapsedContent: some View {
		HStack(spacing: 6) {
			Image(systemName: "chevron.right")
				.font(.caption2)
				.foregroundStyle(.tertiary)

			Text(item.name)
				.font(.callout.bold())

			Text(item.sourceURL.path(percentEncoded: false))
				.font(.caption)
				.foregroundStyle(.secondary)
				.lineLimit(1)
				.truncationMode(.middle)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	private var expandedContent: some View {
		VStack(alignment: .leading, spacing: 0) {
			HStack(spacing: 6) {
				Image(systemName: "chevron.down")
					.font(.caption2)
					.foregroundStyle(.tertiary)

				Text(item.name)
					.font(.callout.bold())
			}
			.frame(maxWidth: .infinity, alignment: .leading)

			Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 6) {
				GridRow {
					Text("Path")
						.font(.caption)
						.foregroundStyle(.secondary)
						.gridColumnAlignment(.trailing)

					Text(item.sourceURL.path(percentEncoded: false))
						.font(.callout)
						.textSelection(.enabled)
						.gridColumnAlignment(.leading)
				}

				if let modified = lastModifiedDate {
					GridRow {
						Text("Modified")
							.font(.caption)
							.foregroundStyle(.secondary)

						HStack {
							Text(modified, style: .date)
							Text(modified, style: .time)
						}
						.font(.callout)
					}
				}

				if let frontmatter = item.document?.frontmatter {
					ForEach(sortedFields(from: frontmatter), id: \.key) { field in
						GridRow {
							Text(field.key)
								.font(.caption)
								.foregroundStyle(.secondary)

							Text(field.value)
								.font(.callout)
								.textSelection(.enabled)
						}
					}
				}
			}
			.padding(.top, 6)
		}
	}

	private var lastModifiedDate: Date? {
		try? FileManager.default.attributesOfItem(
			atPath: item.sourceURL.path(percentEncoded: false)
		)[.modificationDate] as? Date
	}

	private func sortedFields(from frontmatter: Frontmatter) -> [(key: String, value: String)] {
		frontmatter.fields
			.sorted { $0.key < $1.key }
			.map { (key: $0.key, value: $0.value) }
	}
}
