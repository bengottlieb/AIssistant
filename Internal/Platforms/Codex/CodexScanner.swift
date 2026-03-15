//
//  CodexScanner.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/25/26.
//

import Foundation

public struct CodexScanner: PlatformScanner {
	public let platformKind: PlatformKind = .codex
	public let category: ContentCategoryKind
	let baseDirectory: URL

	public init(category: ContentCategoryKind, baseDirectory: URL? = nil) {
		self.category = category
		self.baseDirectory = baseDirectory ?? PlatformKind.codex.baseDirectory
	}

	public nonisolated func scan() async throws -> [ContentItem] {
		switch category {
		case .skills: return try scanSkills()
		case .agents: return try scanAgents()
		case .commands, .mcpServers, .projectConfigs, .sharedClaudeMD: return []
		}
	}

	// MARK: - Skills
	private nonisolated func scanSkills() throws -> [ContentItem] {
		let curatedDir = baseDirectory.appending(path: "vendor_imports/skills/skills/.curated")
		var items: [ContentItem] = []
		let fm = FileManager.default

		// Scan ~/.codex/skills for user-level skills
		let userSkillsDir = baseDirectory.appending(path: "skills")
		if fm.fileExists(atPath: userSkillsDir.path(percentEncoded: false)) {
			let skillFolders = try fm.contentsOfDirectory(at: userSkillsDir, includingPropertiesForKeys: nil)
			for skillFolder in skillFolders {
				let skillFile = skillFolder.appending(path: "SKILL.md")
				guard fm.fileExists(atPath: skillFile.path(percentEncoded: false)) else { continue }

				let content = try String(contentsOf: skillFile, encoding: .utf8)
				let document = FrontmatterDocument(rawContent: content)
				let name = document.frontmatter.name ?? skillFolder.lastPathComponent
				items.append(ContentItem(
					name: name,
					itemDescription: document.frontmatter.description,
					sourceURL: skillFile,
					category: .skills,
					platformKind: platformKind,
					document: document,
					rawContent: content
				))
			}
		}

		guard fm.fileExists(atPath: curatedDir.path(percentEncoded: false)) else { return items }

		let skillFolders = try fm.contentsOfDirectory(at: curatedDir, includingPropertiesForKeys: nil)
		for folder in skillFolders {
			let skillFile = folder.appending(path: "SKILL.md")
			guard fm.fileExists(atPath: skillFile.path(percentEncoded: false)) else { continue }

			let content = try String(contentsOf: skillFile, encoding: .utf8)
			let document = FrontmatterDocument(rawContent: content)
			let name = document.frontmatter.name ?? folder.lastPathComponent

			items.append(ContentItem(
				name: name,
				itemDescription: document.frontmatter.description,
				sourceURL: skillFile,
				category: .skills,
				platformKind: platformKind,
				document: document,
				rawContent: content
			))
		}

		return items
	}

	// MARK: - Agents
	private nonisolated func scanAgents() throws -> [ContentItem] {
		let curatedDir = baseDirectory.appending(path: "vendor_imports/skills/skills/.curated")
		var items: [ContentItem] = []
		let fm = FileManager.default

		guard fm.fileExists(atPath: curatedDir.path(percentEncoded: false)) else { return items }

		let skillFolders = try fm.contentsOfDirectory(at: curatedDir, includingPropertiesForKeys: nil)
		for folder in skillFolders {
			let agentFile = folder.appending(path: "agents/openai.yaml")
			guard fm.fileExists(atPath: agentFile.path(percentEncoded: false)) else { continue }

			let content = try String(contentsOf: agentFile, encoding: .utf8)
			let name = folder.lastPathComponent

			items.append(ContentItem(
				name: name,
				itemDescription: "Codex agent configuration",
				sourceURL: agentFile,
				category: .agents,
				platformKind: platformKind,
				rawContent: content
			))
		}

		return items
	}
}
