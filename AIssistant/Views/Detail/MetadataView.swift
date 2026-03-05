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

	private static let extendedThreshold = 120

	var body: some View {
		let allFields = item.document.map { sortedFields(from: $0.frontmatter) } ?? []
		let hasExtendedFields = allFields.contains { isExtended($0.value) }

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

			ForEach(allFields, id: \.key) { field in
				GridRow {
					Text(field.key)
						.font(.caption)
						.foregroundStyle(.secondary)

					Text(isExpanded ? field.value : truncated(field.value))
						.font(.callout)
						.textSelection(.enabled)
				}
			}

			if hasExtendedFields {
				GridRow {
					Color.clear
						.gridCellUnsizedAxes([.horizontal, .vertical])

					Button {
						withAnimation { isExpanded.toggle() }
					} label: {
						HStack(spacing: 4) {
							Image(systemName: isExpanded ? "chevron.up" : "chevron.right")
								.font(.caption2)
							Text(isExpanded ? "Show less" : "Show more")
								.font(.caption)
						}
						.foregroundStyle(.secondary)
					}
					.buttonStyle(.plain)
				}
			}
		}
	}

	private var lastModifiedDate: Date? {
		try? FileManager.default.attributesOfItem(
			atPath: item.sourceURL.path(percentEncoded: false)
		)[.modificationDate] as? Date
	}

	private func isExtended(_ value: String) -> Bool {
		value.contains("\n") || value.count > Self.extendedThreshold
	}

	private func truncated(_ value: String) -> String {
		guard isExtended(value) else { return value }
		// Take the first line or first chunk up to the threshold
		let firstLine = value.prefix(while: { $0 != "\n" })
		let candidate = firstLine.count > Self.extendedThreshold
			? firstLine.prefix(Self.extendedThreshold)
			: firstLine
		return candidate + "…"
	}

	private func sortedFields(from frontmatter: Frontmatter) -> [(key: String, value: String)] {
		frontmatter.fields
			.sorted { $0.key < $1.key }
			.map { (key: $0.key, value: $0.value) }
	}
}
