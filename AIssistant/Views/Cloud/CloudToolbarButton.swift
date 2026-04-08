//
//  CloudToolbarButton.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 3/1/26.
//

import SwiftUI
import Internal

struct CloudToolbarButton: View {
	let item: ContentItem

	@State private var showingCloudSheet = false
	@Environment(CloudStatusCache.self) private var cloudCache

	var body: some View {
		let status = cloudCache.syncStatus(for: item)

		Button {
			showingCloudSheet = true
		} label: {
			Image(systemName: iconName(for: status))
				.foregroundStyle(iconColor(for: status))
		}
		.disabled(status == .checking)
		.help(helpText(for: status))
		.contextMenu {
			Button("Refresh Cloud") {
				Task { await cloudCache.refresh() }
			}
		}
		.sheet(isPresented: $showingCloudSheet) {
			CloudSyncSheet(item: item)
		}
	}

	private func iconName(for status: CloudStatusCache.SyncStatus) -> String {
		switch status {
		case .checking: "icloud"
		case .notBacked: "xmark.icloud"
		case .synced: "checkmark.icloud"
		case .localNewer: "icloud.and.arrow.up"
		case .cloudNewer: "icloud.and.arrow.down"
		}
	}

	private func iconColor(for status: CloudStatusCache.SyncStatus) -> Color {
		switch status {
		case .checking: .secondary
		case .notBacked: .red
		case .synced: .green
		case .cloudNewer: .yellow
		case .localNewer: .orange
		}
	}

	private func helpText(for status: CloudStatusCache.SyncStatus) -> String {
		switch status {
		case .checking: "Checking iCloud status…"
		case .notBacked: "Not in iCloud"
		case .synced: "Synced with iCloud"
		case .localNewer: "Local changes not yet uploaded"
		case .cloudNewer: "iCloud has a newer version"
		}
	}
}
