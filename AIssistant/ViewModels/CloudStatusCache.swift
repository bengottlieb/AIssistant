//
//  CloudStatusCache.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 3/1/26.
//

import SwiftUI
import SwiftData
import Internal

@Observable
class CloudStatusCache {
	enum SyncStatus {
		case notBacked
		case synced
		case pending
	}

	func syncStatus(for item: ContentItem) -> SyncStatus {
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

	func cloudContent(for item: ContentItem) -> String? {
		let context = CloudSyncService.shared.container.mainContext
		let recordName = item.cloudRecordName

		let predicate = #Predicate<CachedCloudFile> { $0.syncEngineID == recordName }
		let descriptor = FetchDescriptor(predicate: predicate)

		return try? context.fetch(descriptor).first?.content
	}
}
