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

	nonisolated func scan() async throws -> [ContentItem]
}
