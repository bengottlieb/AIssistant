//
//  CloudSyncService.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/1/26.
//

import SwiftData
import SyncEngine
import Suite
import UniformTypeIdentifiers

@MainActor
public final class CloudSyncService {
	public static let shared = CloudSyncService()

	public let container: ModelContainer
	private var dataSource: CloudSyncDataSource?

    static var directory: URL { URL.applicationSupport.appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true).appendingPathComponent("Database", isDirectory: true) }
    
	private init() {
        let url = Self.directory.appendingPathComponent("database.db", conformingTo: .database)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let config = ModelConfiguration(url: url, cloudKitDatabase: .none)
		container = try! ModelContainer(for: CachedCloudFile.self, configurations: config)
        print("Created database at \(url.path(percentEncoded: false))")
	}

	public func setup() async {
		CloudKitInterface.instance.setup(containerID: "iCloud.com.standalone.aissistant")

		SyncEngine.instance.registerPersistedTypes(CachedCloudFile.self)

		var config = SyncEngine.Configuration()
        config.stateDirectory = Self.directory
		config.identifier = "iCloud.com.standalone.aissistant"
		config.automaticallySync = true
		await SyncEngine.instance.setConfiguration(config)

		let source = CloudSyncDataSource(container: container)
		self.dataSource = source
		await SyncEngine.instance.setDataSource(source)
		
		Task {
			do {
				try await SyncEngine.instance.sync()
			} catch {
				print("Sync failed: \(error)")
			}
		}
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

		file.content = (try? String(contentsOf: item.sourceURL, encoding: .utf8)) ?? item.rawContent
		file.fileName = item.sourceURL.lastPathComponent
		file.platform = item.isSharedClaudeMD ? ContentItem.sharedCloudPrefix : item.platformKind.cloudPrefix
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
