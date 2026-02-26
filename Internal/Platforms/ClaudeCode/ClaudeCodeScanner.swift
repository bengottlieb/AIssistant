//
//  ClaudeCodeScanner.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/25/26.
//

import Foundation

public struct ClaudeCodeScanner: PlatformScanner {
	public let platformKind: PlatformKind = .claudeCode
	public let category: ContentCategoryKind

	public init(category: ContentCategoryKind) {
		self.category = category
	}

	public nonisolated func scan() async throws -> [ContentItem] {
		switch category {
		case .skills: return try scanSkills()
		case .agents: return try scanAgents()
		case .commands: return try scanCommands()
		case .mcpServers: return try scanMCPServers()
		case .projectConfigs: return try scanProjectConfigs()
		}
	}

	// MARK: - Skills
	private nonisolated func scanSkills() throws -> [ContentItem] {
		let pluginsDir = platformKind.baseDirectory.appending(path: "plugins/marketplaces")
		var items: [ContentItem] = []
		let fm = FileManager.default

		guard fm.fileExists(atPath: pluginsDir.path(percentEncoded: false)) else { return [] }

		let marketplaces = try fm.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil)
		for marketplace in marketplaces {
			let pluginsPath = marketplace.appending(path: "plugins")
			guard fm.fileExists(atPath: pluginsPath.path(percentEncoded: false)) else { continue }

			let plugins = try fm.contentsOfDirectory(at: pluginsPath, includingPropertiesForKeys: nil)
			for plugin in plugins {
				let skillsDir = plugin.appending(path: "skills")
				guard fm.fileExists(atPath: skillsDir.path(percentEncoded: false)) else { continue }

				let skillFolders = try fm.contentsOfDirectory(at: skillsDir, includingPropertiesForKeys: nil)
				for skillFolder in skillFolders {
					let skillFile = skillFolder.appending(path: "SKILL.md")
					guard fm.fileExists(atPath: skillFile.path(percentEncoded: false)) else { continue }

					if let item = try contentItem(from: skillFile, category: .skills, fallbackName: skillFolder.lastPathComponent) {
						items.append(item)
					}
				}
			}
		}
		return items
	}

	// MARK: - Agents
	private nonisolated func scanAgents() throws -> [ContentItem] {
		let pluginsDir = platformKind.baseDirectory.appending(path: "plugins/marketplaces")
		var items: [ContentItem] = []
		let fm = FileManager.default

		guard fm.fileExists(atPath: pluginsDir.path(percentEncoded: false)) else { return [] }

		let marketplaces = try fm.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil)
		for marketplace in marketplaces {
			let pluginsPath = marketplace.appending(path: "plugins")
			guard fm.fileExists(atPath: pluginsPath.path(percentEncoded: false)) else { continue }

			let plugins = try fm.contentsOfDirectory(at: pluginsPath, includingPropertiesForKeys: nil)
			for plugin in plugins {
				let agentsDir = plugin.appending(path: "agents")
				guard fm.fileExists(atPath: agentsDir.path(percentEncoded: false)) else { continue }

				let agentFiles = try fm.contentsOfDirectory(at: agentsDir, includingPropertiesForKeys: nil)
					.filter { $0.pathExtension == "md" }

				for agentFile in agentFiles {
					if let item = try contentItem(from: agentFile, category: .agents) {
						items.append(item)
					}
				}
			}
		}
		return items
	}

	// MARK: - Commands
	private nonisolated func scanCommands() throws -> [ContentItem] {
		let pluginsDir = platformKind.baseDirectory.appending(path: "plugins/marketplaces")
		var items: [ContentItem] = []
		let fm = FileManager.default

		guard fm.fileExists(atPath: pluginsDir.path(percentEncoded: false)) else { return [] }

		let marketplaces = try fm.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil)
		for marketplace in marketplaces {
			let pluginsPath = marketplace.appending(path: "plugins")
			guard fm.fileExists(atPath: pluginsPath.path(percentEncoded: false)) else { continue }

			let plugins = try fm.contentsOfDirectory(at: pluginsPath, includingPropertiesForKeys: nil)
			for plugin in plugins {
				let commandsDir = plugin.appending(path: "commands")
				guard fm.fileExists(atPath: commandsDir.path(percentEncoded: false)) else { continue }

				let commandFiles = try fm.contentsOfDirectory(at: commandsDir, includingPropertiesForKeys: nil)
					.filter { $0.pathExtension == "md" }

				for commandFile in commandFiles {
					if let item = try contentItem(from: commandFile, category: .commands) {
						items.append(item)
					}
				}
			}
		}
		return items
	}

	// MARK: - MCP Servers
	private nonisolated func scanMCPServers() throws -> [ContentItem] {
		var items: [ContentItem] = []
		let fm = FileManager.default

		// Check for .mcp.json in ~/.claude/
		let mcpFile = platformKind.baseDirectory.appending(path: ".mcp.json")
		if fm.fileExists(atPath: mcpFile.path(percentEncoded: false)) {
			let data = try Data(contentsOf: mcpFile)
			let config = try JSONDecoder().decode(MCPServerConfig.self, from: data)

			if let servers = config.mcpServers {
				for (name, entry) in servers {
					let description = [entry.type, entry.url, entry.command].compactMap { $0 }.joined(separator: " — ")
					items.append(ContentItem(
						name: name,
						itemDescription: description.isEmpty ? nil : description,
						sourceURL: mcpFile,
						category: .mcpServers,
						platformKind: platformKind,
						rawContent: String(data: data, encoding: .utf8) ?? ""
					))
				}
			}
		}

		// Also scan plugin directories for .mcp.json
		let pluginsDir = platformKind.baseDirectory.appending(path: "plugins/marketplaces")
		guard fm.fileExists(atPath: pluginsDir.path(percentEncoded: false)) else { return items }

		let marketplaces = try fm.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil)
		for marketplace in marketplaces {
			let pluginsPath = marketplace.appending(path: "plugins")
			guard fm.fileExists(atPath: pluginsPath.path(percentEncoded: false)) else { continue }

			let plugins = try fm.contentsOfDirectory(at: pluginsPath, includingPropertiesForKeys: nil)
			for plugin in plugins {
				let pluginMcp = plugin.appending(path: ".mcp.json")
				guard fm.fileExists(atPath: pluginMcp.path(percentEncoded: false)) else { continue }

				let data = try Data(contentsOf: pluginMcp)
				let config = try JSONDecoder().decode(MCPServerConfig.self, from: data)

				if let servers = config.mcpServers {
					for (name, entry) in servers {
						let description = [entry.type, entry.url, entry.command].compactMap { $0 }.joined(separator: " — ")
						items.append(ContentItem(
							name: "\(plugin.lastPathComponent)/\(name)",
							itemDescription: description.isEmpty ? nil : description,
							sourceURL: pluginMcp,
							category: .mcpServers,
							platformKind: platformKind,
							rawContent: String(data: data, encoding: .utf8) ?? ""
						))
					}
				}
			}
		}

		return items
	}

	// MARK: - Project Configs
	private nonisolated func scanProjectConfigs() throws -> [ContentItem] {
		var items: [ContentItem] = []
		let fm = FileManager.default

		let configFiles = ["settings.json", "settings.local.json"]
		for configFile in configFiles {
			let fileURL = platformKind.baseDirectory.appending(path: configFile)
			guard fm.fileExists(atPath: fileURL.path(percentEncoded: false)) else { continue }

			let content = try String(contentsOf: fileURL, encoding: .utf8)
			items.append(ContentItem(
				name: configFile,
				itemDescription: "Claude Code configuration",
				sourceURL: fileURL,
				category: .projectConfigs,
				platformKind: platformKind,
				rawContent: content
			))
		}

		// Scan for CLAUDE.md in the base directory
		let claudeMD = platformKind.baseDirectory.appending(path: "CLAUDE.md")
		if fm.fileExists(atPath: claudeMD.path(percentEncoded: false)) {
			let content = try String(contentsOf: claudeMD, encoding: .utf8)
			let doc = FrontmatterDocument(rawContent: content)
			items.append(ContentItem(
				name: "CLAUDE.md",
				itemDescription: "Global project instructions",
				sourceURL: claudeMD,
				category: .projectConfigs,
				platformKind: platformKind,
				document: doc,
				rawContent: content
			))
		}

		return items
	}

	// MARK: - Helpers
	private nonisolated func contentItem(from fileURL: URL, category: ContentCategoryKind, fallbackName: String? = nil) throws -> ContentItem? {
		let content = try String(contentsOf: fileURL, encoding: .utf8)
		let document = FrontmatterDocument(rawContent: content)
		let name = document.frontmatter.name ?? fallbackName ?? fileURL.deletingPathExtension().lastPathComponent

		return ContentItem(
			name: name,
			itemDescription: document.frontmatter.description,
			sourceURL: fileURL,
			category: category,
			platformKind: platformKind,
			document: document,
			rawContent: content
		)
	}
}
