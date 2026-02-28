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

	var body: some View {
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

					Text(modified, style: .date)
						.font(.callout)
					+ Text(" ")
						.font(.callout)
					+ Text(modified, style: .time)
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
