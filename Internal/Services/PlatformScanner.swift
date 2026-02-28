//
//  PlatformScanner.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/25/26.
//

import Foundation

public protocol PlatformScanner: Sendable {
	var platformKind: PlatformKind { get }
	var category: ContentCategoryKind { get }
	var watchedDirectories: [URL] { get }

	nonisolated func scan() async throws -> [ContentItem]
}

extension PlatformScanner {
	public var watchedDirectories: [URL] { [] }
}
