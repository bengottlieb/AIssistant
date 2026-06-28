//
//  InspectorOverview.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 6/28/26.
//

import SwiftUI
import Internal

struct InspectorOverview: View {
	let item: ContentItem
	let entries: [BundleEntry]
	let status: CloudStatusCache.SyncStatus
	let cloudModifiedAt: Date?

	var body: some View {
		GroupBox("Overview") {
			grid {
				row("Platform", item.platformKind.displayName)
				row("Category", item.category.displayName)
				row("Kind", item.isFolderBundle ? "Folder bundle" : "Single file")
				row("State", item.isRemoteOnly ? "Cloud only" : (item.isInstalled ? "Installed" : "Available"))
				if !item.isRemoteOnly {
					row("Location", item.relativePath)
				}
				row("Local files", countLabel(localCount, bytes: localBytes))
			}
		}

		GroupBox("iCloud") {
			grid {
				row("Status", statusText)
				if let cloudModifiedAt {
					row("Cloud modified", cloudModifiedAt.formatted(date: .abbreviated, time: .shortened))
				}
				row("Cloud files", status == .notBacked ? "—" : countLabel(cloudCount, bytes: cloudBytes))
				row("Record") { Text(item.cloudRecordName).font(.system(.caption, design: .monospaced)).textSelection(.enabled) }
			}
		}

		if let fields = item.document?.frontmatter.fields, !fields.isEmpty {
			GroupBox("Metadata") {
				grid {
					ForEach(fields.keys.sorted(), id: \.self) { key in
						row(key, fields[key] ?? "")
					}
				}
			}
		}
	}

	private var localCount: Int { entries.filter { $0.localBytes != nil }.count }
	private var localBytes: Int { entries.compactMap(\.localBytes).reduce(0, +) }
	private var cloudCount: Int { entries.filter { $0.cloudBytes != nil }.count }
	private var cloudBytes: Int { entries.compactMap(\.cloudBytes).reduce(0, +) }

	private func countLabel(_ count: Int, bytes: Int) -> String {
		"\(count) file\(count == 1 ? "" : "s") · \(ByteCountFormatter().string(fromByteCount: Int64(bytes)))"
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

	private func grid<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
		Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 6) {
			content()
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	private func row(_ label: String, _ value: String) -> some View {
		row(label) { Text(value).textSelection(.enabled) }
	}

	private func row<Value: View>(_ label: String, @ViewBuilder value: () -> Value) -> some View {
		GridRow {
			Text(label)
				.foregroundStyle(.secondary)
				.gridColumnAlignment(.leading)
			value()
				.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
}
