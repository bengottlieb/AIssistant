//
//  ContentItemRow.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import Internal

struct ContentItemRow: View {
	let item: ContentItem

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(item.name)
				.font(.headline)

			if let description = item.itemDescription {
				Text(description)
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.lineLimit(2)
			}

			Text(item.relativePath)
				.font(.caption)
				.foregroundStyle(.tertiary)
				.lineLimit(1)
		}
		.padding(.vertical, 2)
	}
}
