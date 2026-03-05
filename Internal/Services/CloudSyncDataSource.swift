//
//  CloudSyncDataSource.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/1/26.
//

import SwiftData
import SyncEngine

public final class CloudSyncDataSource: SyncEngineDataSource {
	public func zoneSyncStarted(_ zoneID: CKRecordZone.ID) {
	}
	
	public func zoneSyncCompleted(_ zoneID: CKRecordZone.ID) {
	}
	
	let container: ModelContainer

	public init(container: ModelContainer) {
		self.container = container
	}

	@MainActor private var context: ModelContext { container.mainContext }

	public func pendingModifications(batchSize: Int) async -> [CKRecord] {
		await MainActor.run {
			let modified = context.modifiedModels(CachedCloudFile.self)
			return Array(modified.prefix(batchSize)).map { $0.ckRecord }
		}
	}

	public func resolveConflict(with record: CKRecord) async {
		await MainActor.run {
			context.handleModifiedCloudRecords([record])
		}
	}

	public func markRecordSaved(_ record: CKRecord) async {
		await MainActor.run {
			if let file: CachedCloudFile = context[record] {
				file.clearModifiedAt()
				context.reportedSave()
			}
		}
	}

	public func didDeleteRecords(_ records: [SyncEngine.DeletedRecord]) async {
		await MainActor.run {
			for record in records {
				context.delete(recordID: record.id, recordType: record.type)
			}
			context.reportedSave()
		}
	}
	
	public func modifiedRecords(_ records: [CKRecord]) async {
		await MainActor.run {
			context.handleModifiedCloudRecords(records)

			for record in records {
				if let file: CachedCloudFile = context[record] {
					CloudSyncFileWriter.writeToLocalDisk(file)
				}
			}
		}
	}
	
	public func existingRecord(matching id: CKRecord.ID) async -> CKRecord? {
		await MainActor.run {
			let existing: CachedCloudFile? = context[id.recordName]
			return existing?.ckRecord
		}
	}

	public func didFinishLoadingRecords() async { }
}
