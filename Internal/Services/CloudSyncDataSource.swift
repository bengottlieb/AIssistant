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
        print(self.container.configurations.first!)
	}

	@MainActor private var context: ModelContext { container.mainContext }

	public func pendingModifications(batchSize: Int?) async -> [CKRecord] {
		await MainActor.run {
			let modified = context.modifiedModels(CachedCloudFile.self)
            guard let batchSize else { return modified.map { $0.ckRecord }}
			return Array(modified.prefix(batchSize)).map { $0.ckRecord }
		}
	}

	public func resolveConflict(with record: CKRecord) async {
		_ = await MainActor.run {
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
	
    public func didDownloadRecords(_ records: [CKRecord]) async -> [AssetUpdateInfo] {
		await MainActor.run {
			let _ = context.handleModifiedCloudRecords(records)
		}
        return []
	}
	
	public func existingRecord(matching id: CKRecord.ID) async -> CKRecord? {
		await MainActor.run {
			let existing: CachedCloudFile? = context[id.recordName]
			return existing?.ckRecord
		}
	}
    
    public func pendingAssets() async -> [AssetUpdateInfo] { [] }
    
    public func didDownloadAsset(_ record: CKRecord, forParentID: String) async { }
    
    public func didUploadAsset(_ record: CKRecord, forParentID: String) async { }
    
    public func record(matching: CKRecord.ID) async -> CKRecord? {
        await MainActor.run {
            let existing: CachedCloudFile? = context[matching.recordName]
            if let record = existing?.ckRecord { return record }
            
            return existing?.ckRecord
        }
    }
    
    public func syncCompleted(withError: (any Error)?) async { }
    
    public func zoneSyncStarted(_ zoneID: CKRecordZone.ID) { }
    
    public func zoneSyncCompleted(_ zoneID: CKRecordZone.ID) { }
    
	public func didFinishLoadingRecords() async { }
}
