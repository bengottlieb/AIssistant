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
			Label("Cloud", systemImage: status == .notBacked ? "cloud" : "cloud.fill")
		}
		.sheet(isPresented: $showingCloudSheet) {
			CloudSyncSheet(item: item)
		}
	}
}
