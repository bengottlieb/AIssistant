//
//  BundleFile.swift
//  Internal
//
//  Created by Ben Gottlieb on 6/28/26.
//

import Foundation

/// One file within a folder-based bundle (a skill or plugin), captured for
/// cloud sync. `path` is relative to the platform's base directory so the file
/// round-trips to the same location when restored on another machine.
public struct BundleFile: Codable, Sendable, Hashable {
	public let path: String
	public let data: Data

	public init(path: String, data: Data) {
		self.path = path
		self.data = data
	}
}
