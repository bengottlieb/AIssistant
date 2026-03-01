//
//  CachedCloudFile.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/1/26.
//

import SwiftData
import SyncEngine

@Model
public final class CachedCloudFile: PersistedCKRecord {
	public static let ckRecordType: CKRecord.RecordType = "AIFile"

	public var modifiedAt: Date = Date()
	public var changeRecordedAt: Date?
	public var syncEngineID: String = ""
	public var cachedRecordData: Data?

	public var content: String = ""
	public var fileName: String = ""
	public var platform: String = ""
	public var category: String = ""
	public var relativePath: String = ""

	public var ckRecordName: String { syncEngineID }
	public var ckRecordZoneID: CKRecordZone.ID { .default }

	public required init() { }

	public func populateCloudRecord(_ record: CKRecord) {
		record[AIFileFields.content] = content
		record[AIFileFields.fileName] = fileName
		record[AIFileFields.platform] = platform
		record[AIFileFields.category] = category
		record[AIFileFields.relativePath] = relativePath
	}

	public func load(fromCloud record: CKRecord, context: ModelContext) -> Bool {
		content = record[AIFileFields.content] ?? ""
		fileName = record[AIFileFields.fileName] ?? ""
		platform = record[AIFileFields.platform] ?? ""
		category = record[AIFileFields.category] ?? ""
		relativePath = record[AIFileFields.relativePath] ?? ""
		return true
	}

	public func resolveConflict(with cloudRecord: CKRecord, newer: NewerRecord, context: ModelContext) {
		_ = load(fromCloud: cloudRecord, context: context)
	}
}
