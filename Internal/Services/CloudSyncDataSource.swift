//
//  CloudSyncDataSource.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/1/26.
//

import SwiftData
import SyncEngine

public final class CloudSyncDataSource: SyncEngineDataSource {
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

	public func modifiedRecord(_ record: CKRecord) async {
		await MainActor.run {
			context.handleModifiedCloudRecord(record)
			if let file: CachedCloudFile = context[record] {
				CloudSyncFileWriter.writeToLocalDisk(file)
			}
		}
	}

	public func resolveConflict(with record: CKRecord) async {
		await MainActor.run {
			context.handleModifiedCloudRecord(record)
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

	public func didDeleteRecord(id: CKRecord.ID, type: CKRecord.RecordType) async {
		await MainActor.run {
			context.delete(recordID: id, recordType: type)
			context.reportedSave()
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
