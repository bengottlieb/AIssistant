//
//  BundleArchive.swift
//  Internal
//
//  Created by Ben Gottlieb on 6/28/26.
//

import Foundation

/// Serializes a folder-based bundle (skill/plugin) to and from a flat list of
/// `BundleFile`s for cloud storage. Paths are stored relative to the platform
/// base directory, so a bundle restores to the same location it came from.
public enum BundleArchive {
	/// Soft ceiling; CloudKit rejects records whose non-asset fields exceed ~1MB.
	static let warnByteThreshold = 900_000

	/// JSON-encode every regular file under `root` (recursively), with paths
	/// relative to `base`. Returns nil when `root` isn't under `base` or holds
	/// no files — callers then fall back to single-file upload.
	public static func archive(root: URL, base: URL) -> Data? {
		let fm = FileManager.default
		let basePath = base.path(percentEncoded: false)
		let rootPath = root.path(percentEncoded: false)
		guard rootPath == basePath || rootPath.hasPrefix(basePath + "/") else { return nil }
		guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey]) else { return nil }

		var files: [BundleFile] = []
		for case let url as URL in enumerator {
			guard (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { continue }
			guard url.lastPathComponent != ".DS_Store" else { continue }
			guard let data = try? Data(contentsOf: url) else { continue }
			let full = url.path(percentEncoded: false)
			guard full.hasPrefix(basePath + "/") else { continue }
			files.append(BundleFile(path: String(full.dropFirst(basePath.count + 1)), data: data))
		}

		guard !files.isEmpty, let json = try? JSONEncoder().encode(files) else { return nil }
		if json.count > warnByteThreshold {
			print("BundleArchive: \(root.lastPathComponent) is \(json.count) bytes — may exceed CloudKit's per-record limit")
		}
		return json
	}

	/// Write every `BundleFile` in `data` under `base`, creating intermediate
	/// directories. Returns false if decoding or any write fails.
	@discardableResult
	public static func restore(_ data: Data, to base: URL) -> Bool {
		guard let files = try? JSONDecoder().decode([BundleFile].self, from: data) else { return false }
		let fm = FileManager.default
		var success = true
		for file in files {
			let destination = base.appending(path: file.path)
			do {
				try fm.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
				try file.data.write(to: destination)
			} catch {
				print("BundleArchive: failed to write \(file.path): \(error)")
				success = false
			}
		}
		return success
	}
}
