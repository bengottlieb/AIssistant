//
//  MetadataView.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import Internal

struct MetadataView: View {
	let frontmatter: Frontmatter

	var body: some View {
		Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 6) {
			ForEach(sortedFields, id: \.key) { field in
				GridRow {
					Text(field.key)
						.font(.caption)
						.foregroundStyle(.secondary)
						.gridColumnAlignment(.trailing)

					Text(field.value)
						.font(.callout)
						.textSelection(.enabled)
						.gridColumnAlignment(.leading)
				}
			}
		}
	}

	private var sortedFields: [(key: String, value: String)] {
		frontmatter.fields
			.sorted { $0.key < $1.key }
			.map { (key: $0.key, value: $0.value) }
	}
}
