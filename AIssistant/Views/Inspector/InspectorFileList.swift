//
//  InspectorFileList.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 6/28/26.
//

import SwiftUI
import Internal

struct InspectorFileList: View {
	let entries: [BundleEntry]

	private var manifestCount: Int { entries.filter { $0.cloudBytes != nil }.count }

	var body: some View {
		GroupBox(title) {
			if entries.isEmpty {
				Text("No files")
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, alignment: .leading)
			} else {
				Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 5) {
					GridRow {
						Color.clear.frame(width: 16, height: 0)
						Text("File").gridColumnAlignment(.leading)
						Text("Local").gridColumnAlignment(.trailing)
						Text("iCloud").gridColumnAlignment(.trailing)
					}
					.font(.caption.weight(.semibold))
					.foregroundStyle(.secondary)

					ForEach(entries) { entry in
						GridRow {
							Image(systemName: icon(for: entry.state))
								.foregroundStyle(color(for: entry.state))
								.help(helpText(for: entry.state))
							Text(entry.path)
								.font(.system(.caption, design: .monospaced))
								.lineLimit(1)
								.truncationMode(.head)
								.textSelection(.enabled)
								.help(entry.path)
								.frame(maxWidth: .infinity, alignment: .leading)
							Text(sizeLabel(entry.localBytes))
								.font(.caption)
								.foregroundStyle(.secondary)
							Text(sizeLabel(entry.cloudBytes))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}
				}
				.frame(maxWidth: .infinity, alignment: .leading)
			}
		}
	}

	private var title: String {
		manifestCount > 0
			? "Files (\(entries.count)) · \(manifestCount) in iCloud manifest"
			: "Files (\(entries.count))"
	}

	private func sizeLabel(_ bytes: Int?) -> String {
		guard let bytes else { return "—" }
		return ByteCountFormatter().string(fromByteCount: Int64(bytes))
	}

	private func icon(for state: BundleEntry.State) -> String {
		switch state {
		case .matched: "checkmark.circle.fill"
		case .differs: "exclamationmark.triangle.fill"
		case .localOnly: "internaldrive"
		case .cloudOnly: "icloud"
		}
	}

	private func color(for state: BundleEntry.State) -> Color {
		switch state {
		case .matched: .green
		case .differs: .orange
		case .localOnly: .secondary
		case .cloudOnly: .yellow
		}
	}

	private func helpText(for state: BundleEntry.State) -> String {
		switch state {
		case .matched: "Local and iCloud copies match"
		case .differs: "Local and iCloud copies differ"
		case .localOnly: "Only exists locally (not in the iCloud manifest)"
		case .cloudOnly: "Only in the iCloud manifest (not downloaded)"
		}
	}
}
