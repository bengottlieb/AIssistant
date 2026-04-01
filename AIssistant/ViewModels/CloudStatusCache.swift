//
//  CloudStatusCache.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 3/1/26.
//

import SwiftUI
import SwiftData
import Internal
import SyncEngine

@Observable
class CloudStatusCache {
	enum SyncStatus {
		case checking
		case notBacked
		case synced
		case pending
	}

	private(set) var hasRefreshed = false

	func syncStatus(for item: ContentItem) -> SyncStatus {
		if !hasRefreshed { return .checking }

		let context = CloudSyncService.shared.container.mainContext
		let recordName = item.cloudRecordName

		let predicate = #Predicate<CachedCloudFile> { $0.syncEngineID == recordName }
		let descriptor = FetchDescriptor(predicate: predicate)

		guard let file = try? context.fetch(descriptor).first else {
			return .notBacked
		}

		if file.changeRecordedAt != nil {
			return .pending
		}
		return .synced
	}

	func refresh() async {
		hasRefreshed = false
		do {
			try await SyncEngine.instance.sync()
		} catch {
			print("Cloud refresh failed: \(error)")
		}
		hasRefreshed = true
	}

	func cloudContent(for item: ContentItem) -> String? {
		let context = CloudSyncService.shared.container.mainContext
		let recordName = item.cloudRecordName

		let predicate = #Predicate<CachedCloudFile> { $0.syncEngineID == recordName }
		let descriptor = FetchDescriptor(predicate: predicate)

		return try? context.fetch(descriptor).first?.content
	}
}
