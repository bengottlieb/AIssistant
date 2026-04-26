//
//  ContentItem+Cloud.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/1/26.
//

import Foundation

public extension PlatformKind {
	var cloudPrefix: String {
		switch self {
		case .claudeCode: "Claude"
		case .codex: "Codex"
		}
	}

	init?(cloudPrefix: String) {
		switch cloudPrefix {
		case "Claude": self = .claudeCode
		case "Codex": self = .codex
		default: return nil
		}
	}
}

public extension ContentItem {
	static let sharedCloudPrefix = "Shared"

	var isSharedClaudeMD: Bool {
		sourceURL == ContentItem.sharedClaudeMDURL
	}

	var cloudRecordName: String {
		if isSharedClaudeMD { return "\(Self.sharedCloudPrefix)/CLAUDE.md" }
		return "\(platformKind.cloudPrefix)/\(cloudRelativePath)"
	}

	var cloudRelativePath: String {
		if isSharedClaudeMD { return "CLAUDE.md" }
		let base = platformKind.baseDirectory.path(percentEncoded: false)
		return sourceURL.path(percentEncoded: false)
			.replacingOccurrences(of: base + "/", with: "")
	}

	static func remoteOnly(from file: CachedCloudFile) -> ContentItem? {
		guard let platformKind = PlatformKind(cloudPrefix: file.platform) else { return nil }
		guard let category = ContentCategoryKind(rawValue: file.category) else { return nil }

		let destinationURL = platformKind.baseDirectory.appending(path: file.relativePath)
		let document = FrontmatterDocument(rawContent: file.content)
		let frontmatterName = document.frontmatter.name
		let isSkillBundle = file.fileName == "SKILL.md"
		let derivedName = frontmatterName ?? deriveDisplayName(
			fileName: file.fileName,
			relativePath: file.relativePath,
			isSkillBundle: isSkillBundle
		)

		return ContentItem(
			name: derivedName,
			itemDescription: document.frontmatter.description,
			sourceURL: destinationURL,
			category: category,
			platformKind: platformKind,
			document: document,
			rawContent: file.content,
			isInstalled: false,
			isRemoteOnly: true
		)
	}

	private static func deriveDisplayName(fileName: String, relativePath: String, isSkillBundle: Bool) -> String {
		if isSkillBundle {
			let url = URL(filePath: relativePath)
			return url.deletingLastPathComponent().lastPathComponent
		}
		return (fileName as NSString).deletingPathExtension
	}
}
