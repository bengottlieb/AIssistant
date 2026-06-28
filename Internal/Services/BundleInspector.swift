//
//  BundleInspector.swift
//  Internal
//
//  Created by Ben Gottlieb on 6/28/26.
//

import Foundation

/// One file in an item's merged local/cloud listing, used by the inspector.
public struct BundleEntry: Identifiable, Sendable, Hashable {
	public enum State: Sendable { case matched, differs, localOnly, cloudOnly }
	public var id: String { path }
	public let path: String          // relative to the platform base directory
	public let localBytes: Int?
	public let cloudBytes: Int?
	public let state: State
}

/// Compares an item's on-disk files against its cached cloud record so the
/// inspector can show, per file, whether it matches, differs, or exists on only
/// one side. Handles both folder bundles (skills/plugins) and single files.
@MainActor
public enum BundleInspector {
	public static func entries(for item: ContentItem, cloudFile: CachedCloudFile?) -> [BundleEntry] {
		let base = item.platformKind.baseDirectory
		let local = localFiles(for: item, base: base)
		let cloud = cloudFiles(from: cloudFile)

		return Set(local.keys).union(cloud.keys).sorted().map { path in
			let localData = local[path]
			let cloudData = cloud[path]
			let state: BundleEntry.State
			switch (localData, cloudData) {
			case let (l?, c?): state = (l == c) ? .matched : .differs
			case (_?, nil): state = .localOnly
			case (nil, _?): state = .cloudOnly
			case (nil, nil): state = .matched
			}
			return BundleEntry(path: path, localBytes: localData?.count, cloudBytes: cloudData?.count, state: state)
		}
	}

	private static func localFiles(for item: ContentItem, base: URL) -> [String: Data] {
		let fm = FileManager.default
		let basePath = base.path(percentEncoded: false)
		var result: [String: Data] = [:]

		if let root = item.bundleRootURL {
			guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey]) else { return [:] }
			for case let url as URL in enumerator {
				guard (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { continue }
				guard url.lastPathComponent != ".DS_Store" else { continue }
				let full = url.path(percentEncoded: false)
				guard full.hasPrefix(basePath + "/"), let data = try? Data(contentsOf: url) else { continue }
				result[String(full.dropFirst(basePath.count + 1))] = data
			}
		} else if let data = try? Data(contentsOf: item.sourceURL) {
			result[item.cloudRelativePath] = data
		}
		return result
	}

	private static func cloudFiles(from cloudFile: CachedCloudFile?) -> [String: Data] {
		guard let cloudFile else { return [:] }
		if let bundleData = cloudFile.bundleData,
		   let files = try? JSONDecoder().decode([BundleFile].self, from: bundleData) {
			return Dictionary(files.map { ($0.path, $0.data) }, uniquingKeysWith: { first, _ in first })
		}
		return [cloudFile.relativePath: Data(cloudFile.content.utf8)]
	}
}
