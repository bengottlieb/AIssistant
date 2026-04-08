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
		case .plugins, .commands, .mcpServers, .projectConfigs, .sharedClaudeMD: return []
		}
	}

	// MARK: - Skills (installed + curated/available)
	private nonisolated func scanSkills() throws -> [ContentItem] {
		var items: [ContentItem] = []
		var installedNames: Set<String> = []
		let fm = FileManager.default

		let userSkillsDir = baseDirectory.appending(path: "skills")
		if fm.fileExists(atPath: userSkillsDir.path(percentEncoded: false)) {
			for skillFolder in try fm.contentsOfDirectory(at: userSkillsDir, includingPropertiesForKeys: nil) {
				let skillFile = skillFolder.appending(path: "SKILL.md")
				guard fm.fileExists(atPath: skillFile.path(percentEncoded: false)) else { continue }
				let content = try String(contentsOf: skillFile, encoding: .utf8)
				let document = FrontmatterDocument(rawContent: content)
				let name = document.frontmatter.name ?? skillFolder.lastPathComponent
				installedNames.insert(name)
				items.append(ContentItem(
					name: name,
					itemDescription: document.frontmatter.description,
					sourceURL: skillFile,
					category: .skills,
					platformKind: platformKind,
					document: document,
					rawContent: content,
					isInstalled: true
				))
			}
		}

		let curatedDir = baseDirectory.appending(path: "vendor_imports/skills/skills/.curated")
		guard fm.fileExists(atPath: curatedDir.path(percentEncoded: false)) else { return items }

		for folder in try fm.contentsOfDirectory(at: curatedDir, includingPropertiesForKeys: nil) {
			let skillFile = folder.appending(path: "SKILL.md")
			guard fm.fileExists(atPath: skillFile.path(percentEncoded: false)) else { continue }
			let content = try String(contentsOf: skillFile, encoding: .utf8)
			let document = FrontmatterDocument(rawContent: content)
			let name = document.frontmatter.name ?? folder.lastPathComponent
			guard !installedNames.contains(name) else { continue }
			items.append(ContentItem(
				name: name,
				itemDescription: document.frontmatter.description,
				sourceURL: skillFile,
				category: .skills,
				platformKind: platformKind,
				document: document,
				rawContent: content,
				isInstalled: false
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

		for folder in try fm.contentsOfDirectory(at: curatedDir, includingPropertiesForKeys: nil) {
			let agentFile = folder.appending(path: "agents/openai.yaml")
			guard fm.fileExists(atPath: agentFile.path(percentEncoded: false)) else { continue }
			let content = try String(contentsOf: agentFile, encoding: .utf8)
			items.append(ContentItem(
				name: folder.lastPathComponent,
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
