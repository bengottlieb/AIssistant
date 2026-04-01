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

		Group {
			if status == .checking {
				ProgressView()
					.controlSize(.small)
			} else {
				Button {
					showingCloudSheet = true
				} label: {
					let icon = switch status {
					case .checking: "cloud"
					case .notBacked: "cloud"
					case .synced: "checkmark.icloud"
					case .pending: "cloud.fill"
					}
					Label("Cloud", systemImage: icon)
				}
			}
		}
		.contextMenu {
			Button("Refresh Cloud") {
				Task { await cloudCache.refresh() }
			}
		}
		.sheet(isPresented: $showingCloudSheet) {
			CloudSyncSheet(item: item)
		}
	}
}
