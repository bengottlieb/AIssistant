//
//  ContentItem+SharedClaudeMD.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/14/26.
//

import Foundation

public extension ContentItem {
	static let sharedClaudeMDURL = URL.homeDirectory.appending(path: "CLAUDE.md")

	static var isSharedClaudeMD: (ContentItem) -> Bool = { item in
		item.sourceURL == sharedClaudeMDURL
	}

	static func loadSharedClaudeMD() -> ContentItem {
		let url = sharedClaudeMDURL
		let content: String
		if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
			content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
		} else {
			content = "# CLAUDE.md\n\nShared instructions for Claude Code.\n"
		}

		let document = FrontmatterDocument(rawContent: content)

		return ContentItem(
			name: "CLAUDE.md",
			itemDescription: "Shared Claude instructions (~/CLAUDE.md)",
			sourceURL: url,
			category: .projectConfigs,
			platformKind: .claudeCode,
			document: document,
			rawContent: content
		)
	}
}
