//
//  CloudSyncService.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/1/26.
//

import SwiftData
import SyncEngine

@MainActor
public final class CloudSyncService {
	public static let shared = CloudSyncService()

	public let container: ModelContainer
	private var dataSource: CloudSyncDataSource?

	private init() {
		container = try! ModelContainer(for: CachedCloudFile.self)
	}

	public func setup() async {
		CloudKitInterface.instance.setup(containerID: "iCloud.com.standalone.aissistant")

		SyncEngine.instance.registerPersistedTypes(CachedCloudFile.self)

		var config = SyncEngine.Configuration()
		config.identifier = "iCloud.com.standalone.aissistant"
		config.automaticallySync = true
		await SyncEngine.instance.setConfiguration(config)

		let source = CloudSyncDataSource(container: container)
		self.dataSource = source
		await SyncEngine.instance.setDataSource(source)
	}

	public func upload(_ item: ContentItem) {
		let context = container.mainContext
		let recordName = item.cloudRecordName

		let predicate = #Predicate<CachedCloudFile> { $0.syncEngineID == recordName }
		let descriptor = FetchDescriptor(predicate: predicate)

		let file: CachedCloudFile
		if let existing = try? context.fetch(descriptor).first {
			file = existing
		} else {
			file = CachedCloudFile()
			file.syncEngineID = recordName
			context.insert(file)
		}

		file.content = item.rawContent
		file.fileName = item.sourceURL.lastPathComponent
		file.platform = item.platformKind.cloudPrefix
		file.category = item.category.rawValue
		file.relativePath = item.cloudRelativePath
		file.setModifiedAt()

		context.reportedSave()
		file.reportedSaveAndSync(setModified: true)
	}

	public func delete(_ item: ContentItem) {
		let context = container.mainContext
		let recordName = item.cloudRecordName

		let predicate = #Predicate<CachedCloudFile> { $0.syncEngineID == recordName }
		let descriptor = FetchDescriptor(predicate: predicate)

		if let existing = try? context.fetch(descriptor).first {
			existing.deletePersistedRecord()
		}
	}
}
