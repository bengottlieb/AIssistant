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
		case localNewer
		case cloudNewer
	}

	private(set) var hasRefreshed = false
	private(set) var localChangeCount = 0

	func localFileDidChange() {
		localChangeCount += 1
	}

	func syncStatus(for item: ContentItem) -> SyncStatus {
		_ = localChangeCount
		if !hasRefreshed { return .checking }

		guard let file = CloudSyncService.shared.cachedCloudFile(forRecordName: item.cloudRecordName) else {
			return .notBacked
		}

		let localContent = (try? String(contentsOf: item.sourceURL, encoding: .utf8)) ?? ""
		if localContent == file.content { return .synced }

		let localModDate = (try? FileManager.default.attributesOfItem(atPath: item.sourceURL.path)[.modificationDate] as? Date) ?? .distantPast
		let cloudModDate = file.modifiedAt

		return localModDate > cloudModDate ? .localNewer : .cloudNewer
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
		CloudSyncService.shared.cachedCloudFile(forRecordName: item.cloudRecordName)?.content
	}
}
