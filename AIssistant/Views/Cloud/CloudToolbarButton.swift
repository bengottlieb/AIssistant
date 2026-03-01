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
		Button {
			showingCloudSheet = true
		} label: {
			let status = cloudCache.syncStatus(for: item)
			let icon = switch status {
			case .notBacked: "cloud"
			case .synced: "checkmark.icloud"
			case .pending: "cloud.fill"
			}
			Label("Cloud", systemImage: icon)
		}
		.sheet(isPresented: $showingCloudSheet) {
			CloudSyncSheet(item: item)
		}
	}
}
