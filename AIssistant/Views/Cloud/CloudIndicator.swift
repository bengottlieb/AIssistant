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
		Button {
			showingCloudSheet = true
		} label: {
			let status = cloudCache.syncStatus(for: item)
			Image(systemName: cloudIconName(for: status))
				.foregroundStyle(cloudColor(for: status))
				.font(.caption)
		}
		.buttonStyle(.plain)
		.sheet(isPresented: $showingCloudSheet) {
			CloudSyncSheet(item: item)
		}
	}

	private func cloudIconName(for status: CloudStatusCache.SyncStatus) -> String {
		switch status {
		case .notBacked: "cloud"
		case .synced: "checkmark.icloud"
		case .pending: "cloud.fill"
		}
	}

	private func cloudColor(for status: CloudStatusCache.SyncStatus) -> Color {
		switch status {
		case .notBacked: .secondary
		case .synced: .blue
		case .pending: .orange
		}
	}
}
