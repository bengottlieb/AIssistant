//
//  CloudSyncFileWriter.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/1/26.
//

import Foundation

public enum CloudSyncFileWriter {
	public static func writeToLocalDisk(_ file: CachedCloudFile) {
		guard let platformKind = PlatformKind(cloudPrefix: file.platform) else { return }

		let fileURL = platformKind.baseDirectory.appending(path: file.relativePath)

		do {
			try FileManager.default.createDirectory(
				at: fileURL.deletingLastPathComponent(),
				withIntermediateDirectories: true
			)
			try file.content.write(to: fileURL, atomically: true, encoding: .utf8)
		} catch {
			print("CloudSyncFileWriter: failed to write \(file.fileName): \(error)")
		}
	}
}
