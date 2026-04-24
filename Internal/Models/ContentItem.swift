//
//  ContentItem.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/25/26.
//

import Foundation

public struct ContentItem: Identifiable, Hashable, Sendable {
	public let id: URL
	public let name: String
	public let itemDescription: String?
	public let sourceURL: URL
	public let category: ContentCategoryKind
	public let platformKind: PlatformKind
	public let document: FrontmatterDocument?
	public let rawContent: String
	public let isInstalled: Bool

	public init(
		name: String,
		itemDescription: String? = nil,
		sourceURL: URL,
		category: ContentCategoryKind,
		platformKind: PlatformKind,
		document: FrontmatterDocument? = nil,
		rawContent: String,
		isInstalled: Bool = true
	) {
		self.id = sourceURL
		self.name = name
		self.itemDescription = itemDescription
		self.sourceURL = sourceURL
		self.category = category
		self.platformKind = platformKind
		self.document = document
		self.rawContent = rawContent
		self.isInstalled = isInstalled
	}

	public static func == (lhs: ContentItem, rhs: ContentItem) -> Bool { lhs.id == rhs.id }
	public func hash(into hasher: inout Hasher) { hasher.combine(id) }

	public var isMarkdown: Bool {
		sourceURL.pathExtension.lowercased() == "md"
	}

	public var isJSON: Bool {
		sourceURL.pathExtension.lowercased() == "json"
	}

	public var isSkillBundle: Bool {
		sourceURL.lastPathComponent == "SKILL.md"
	}

	/// Relative path from the platform's base directory
	public var relativePath: String {
		let displayURL = isSkillBundle
			? sourceURL.deletingLastPathComponent()
			: sourceURL
		let path = displayURL.path(percentEncoded: false)
		let homePath = URL.homeDirectory.path(percentEncoded: false)
		return path
			.replacingOccurrences(of: platformKind.baseDirectory.path(percentEncoded: false), with: "~")
			.replacingOccurrences(of: homePath, with: "~/")
	}
}
