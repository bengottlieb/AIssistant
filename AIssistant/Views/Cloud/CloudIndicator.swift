//
//  CloudIndicator.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 3/1/26.
//

import SwiftUI
import Internal

struct CloudIndicator: View {
	let item: ContentItem

	@State private var showingCloudSheet = false
	@Environment(CloudStatusCache.self) private var cloudCache

	var body: some View {
		let status = cloudCache.syncStatus(for: item)

		Button {
			showingCloudSheet = true
		} label: {
			if status == .checking {
				ProgressView()
					.controlSize(.small)
			} else {
				Image(systemName: cloudIconName(for: status))
					.foregroundStyle(cloudColor(for: status))
					.font(.caption)
			}
		}
		.buttonStyle(.plain)
		.contextMenu {
			Button("Refresh Cloud") {
				Task { await cloudCache.refresh() }
			}
		}
		.sheet(isPresented: $showingCloudSheet) {
			CloudSyncSheet(item: item)
		}
	}

	private func cloudIconName(for status: CloudStatusCache.SyncStatus) -> String {
		switch status {
		case .checking: "cloud"
		case .notBacked: "cloud"
		case .synced: "checkmark.icloud"
		case .pending: "cloud.fill"
		}
	}

	private func cloudColor(for status: CloudStatusCache.SyncStatus) -> Color {
		switch status {
		case .checking: .secondary
		case .notBacked: .secondary
		case .synced: .blue
		case .pending: .orange
		}
	}
}
