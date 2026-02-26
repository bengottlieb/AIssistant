//
//  TransferService.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/25/26.
//

import Foundation

public enum TransferService {

	/// Field name mappings between platforms
	private static let fieldMappings: [PlatformKind: [String: String]] = [
		.codex: [
			"description": "short_description",
			"allowed_tools": "allowedTools",
		],
		.claudeCode: [
			"short_description": "description",
			"allowedTools": "allowed_tools",
		],
	]

	/// Copies a content item to the target platform's directory
	public nonisolated static func transfer(_ item: ContentItem, to targetPlatform: PlatformKind) throws -> URL {
		let destinationURL = destinationURL(for: item, in: targetPlatform)
		let fm = FileManager.default

		// Create parent directories
		let parentDir = destinationURL.deletingLastPathComponent()
		try fm.createDirectory(at: parentDir, withIntermediateDirectories: true)

		// Adapt content if it has frontmatter
		var content = item.rawContent
		if let document = item.document, !document.frontmatter.fields.isEmpty {
			content = adaptFrontmatter(document, from: item.platformKind, to: targetPlatform)
		}

		try content.write(to: destinationURL, atomically: true, encoding: .utf8)
		return destinationURL
	}

	/// Computes the destination URL for a content item in the target platform
	public static func destinationURL(for item: ContentItem, in targetPlatform: PlatformKind) -> URL {
		let base = targetPlatform.baseDirectory

		switch targetPlatform {
		case .claudeCode:
			switch item.category {
			case .skills:
				return base.appending(path: "plugins/local/skills/\(item.name)/SKILL.md")
			case .agents:
				return base.appending(path: "plugins/local/agents/\(item.name).md")
			case .commands:
				return base.appending(path: "plugins/local/commands/\(item.name).md")
			case .mcpServers:
				return base.appending(path: ".mcp.json")
			case .projectConfigs:
				return base.appending(path: item.sourceURL.lastPathComponent)
			}

		case .codex:
			switch item.category {
			case .skills:
				return base.appending(path: "vendor_imports/skills/skills/.curated/\(item.name)/SKILL.md")
			case .agents:
				return base.appending(path: "vendor_imports/skills/skills/.curated/\(item.name)/agents/openai.yaml")
			case .commands, .mcpServers, .projectConfigs:
				return base.appending(path: "imported/\(item.sourceURL.lastPathComponent)")
			}
		}
	}

	/// Adapts frontmatter field names when transferring between platforms
	private static func adaptFrontmatter(_ document: FrontmatterDocument, from sourcePlatform: PlatformKind, to targetPlatform: PlatformKind) -> String {
		guard let mappings = fieldMappings[targetPlatform] else {
			return document.rawContent
		}

		var adaptedFields: [String: String] = [:]
		for (key, value) in document.frontmatter.fields {
			let newKey = mappings[key] ?? key
			adaptedFields[newKey] = value
		}

		// Reconstruct the document
		var result = "---\n"
		for (key, value) in adaptedFields.sorted(by: { $0.key < $1.key }) {
			result += "\(key): \(value)\n"
		}
		result += "---\n"

		if !document.body.isEmpty {
			result += "\n\(document.body)\n"
		}

		return result
	}
}
