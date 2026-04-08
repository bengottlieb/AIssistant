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
	let baseDirectory: URL

	public init(category: ContentCategoryKind, baseDirectory: URL? = nil) {
		self.category = category
		self.baseDirectory = baseDirectory ?? PlatformKind.claudeCode.baseDirectory
	}

	public nonisolated func scan() async throws -> [ContentItem] {
		switch category {
		case .skills: return try scanSkills()
		case .plugins: return try scanPluginPackages()
		case .agents: return try scanAgents()
		case .commands: return try scanCommands()
		case .mcpServers: return try scanMCPServers()
		case .projectConfigs: return try scanProjectConfigs()
		case .sharedClaudeMD: return []
		}
	}

	// MARK: - Skills (installed + available from plugins)
	private nonisolated func scanSkills() throws -> [ContentItem] {
		var items: [ContentItem] = []
		var installedNames: Set<String> = []
		let fm = FileManager.default

		let userSkillsDir = baseDirectory.appending(path: "skills")
		if fm.fileExists(atPath: userSkillsDir.path(percentEncoded: false)) {
			for skillFolder in try fm.contentsOfDirectory(at: userSkillsDir, includingPropertiesForKeys: nil) {
				let skillFile = skillFolder.appending(path: "SKILL.md")
				guard fm.fileExists(atPath: skillFile.path(percentEncoded: false)) else { continue }
				if let item = try contentItem(from: skillFile, category: .skills, fallbackName: skillFolder.lastPathComponent, isInstalled: true) {
					installedNames.insert(item.name)
					items.append(item)
				}
			}
		}

		let pluginsDir = baseDirectory.appending(path: "plugins/marketplaces")
		guard fm.fileExists(atPath: pluginsDir.path(percentEncoded: false)) else { return items }

		for marketplace in try fm.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil) {
			let pluginsPath = marketplace.appending(path: "plugins")
			guard fm.fileExists(atPath: pluginsPath.path(percentEncoded: false)) else { continue }

			for plugin in try fm.contentsOfDirectory(at: pluginsPath, includingPropertiesForKeys: nil) {
				let skillsDir = plugin.appending(path: "skills")
				guard fm.fileExists(atPath: skillsDir.path(percentEncoded: false)) else { continue }

				for skillFolder in try fm.contentsOfDirectory(at: skillsDir, includingPropertiesForKeys: nil) {
					let skillFile = skillFolder.appending(path: "SKILL.md")
					guard fm.fileExists(atPath: skillFile.path(percentEncoded: false)) else { continue }
					if let item = try contentItem(from: skillFile, category: .skills, fallbackName: skillFolder.lastPathComponent, isInstalled: false) {
						guard !installedNames.contains(item.name) else { continue }
						items.append(item)
					}
				}
			}
		}
		return items
	}

	// MARK: - Plugin Packages (one item per plugin directory)
	private nonisolated func scanPluginPackages() throws -> [ContentItem] {
		var items: [ContentItem] = []
		let fm = FileManager.default
		let pluginsDir = baseDirectory.appending(path: "plugins/marketplaces")
		guard fm.fileExists(atPath: pluginsDir.path(percentEncoded: false)) else { return items }

		for marketplace in try fm.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil) {
			let pluginsPath = marketplace.appending(path: "plugins")
			guard fm.fileExists(atPath: pluginsPath.path(percentEncoded: false)) else { continue }

			for plugin in try fm.contentsOfDirectory(at: pluginsPath, includingPropertiesForKeys: nil) {
				var isDir: ObjCBool = false
				guard fm.fileExists(atPath: plugin.path(percentEncoded: false), isDirectory: &isDir), isDir.boolValue else { continue }

				let readmeURL = plugin.appending(path: "README.md")
				let rawContent = fm.fileExists(atPath: readmeURL.path(percentEncoded: false))
					? ((try? String(contentsOf: readmeURL, encoding: .utf8)) ?? "")
					: ""
				let description = rawContent.components(separatedBy: .newlines)
					.map { $0.trimmingCharacters(in: .whitespaces) }
					.first { !$0.isEmpty && !$0.hasPrefix("#") }

				let sourceURL = fm.fileExists(atPath: readmeURL.path(percentEncoded: false)) ? readmeURL : plugin
				items.append(ContentItem(
					name: plugin.lastPathComponent,
					itemDescription: description,
					sourceURL: sourceURL,
					category: .plugins,
					platformKind: platformKind,
					rawContent: rawContent
				))
			}
		}
		return items
	}

	// MARK: - Agents
	private nonisolated func scanAgents() throws -> [ContentItem] {
		let pluginsDir = baseDirectory.appending(path: "plugins/marketplaces")
		var items: [ContentItem] = []
		let fm = FileManager.default

		guard fm.fileExists(atPath: pluginsDir.path(percentEncoded: false)) else { return items }

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
		var items: [ContentItem] = []
		let fm = FileManager.default
		var activeFilenames: Set<String> = []

		let userCommandsDir = baseDirectory.appending(path: "commands")
		if fm.fileExists(atPath: userCommandsDir.path(percentEncoded: false)) {
			let commandFiles = try fm.contentsOfDirectory(at: userCommandsDir, includingPropertiesForKeys: nil)
				.filter { $0.pathExtension == "md" }
			for commandFile in commandFiles {
				activeFilenames.insert(commandFile.lastPathComponent)
				if let item = try contentItem(from: commandFile, category: .commands, isInstalled: true) {
					items.append(item)
				}
			}
		}

		let pluginsDir = baseDirectory.appending(path: "plugins/marketplaces")
		guard fm.fileExists(atPath: pluginsDir.path(percentEncoded: false)) else { return items }

		for marketplace in try fm.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil) {
			let pluginsPath = marketplace.appending(path: "plugins")
			guard fm.fileExists(atPath: pluginsPath.path(percentEncoded: false)) else { continue }

			for plugin in try fm.contentsOfDirectory(at: pluginsPath, includingPropertiesForKeys: nil) {
				let commandsDir = plugin.appending(path: "commands")
				guard fm.fileExists(atPath: commandsDir.path(percentEncoded: false)) else { continue }

				let commandFiles = try fm.contentsOfDirectory(at: commandsDir, includingPropertiesForKeys: nil)
					.filter { $0.pathExtension == "md" }
				for commandFile in commandFiles {
					guard !activeFilenames.contains(commandFile.lastPathComponent) else { continue }
					if let item = try contentItem(from: commandFile, category: .commands, namePrefix: plugin.lastPathComponent, isInstalled: false) {
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

		let mcpFile = baseDirectory.appending(path: ".mcp.json")
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
						rawContent: String(data: data, encoding: .utf8) ?? "",
						isInstalled: true
					))
				}
			}
		}

		let pluginsDir = baseDirectory.appending(path: "plugins/marketplaces")
		guard fm.fileExists(atPath: pluginsDir.path(percentEncoded: false)) else { return items }

		for marketplace in try fm.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil) {
			let pluginsPath = marketplace.appending(path: "plugins")
			guard fm.fileExists(atPath: pluginsPath.path(percentEncoded: false)) else { continue }

			for plugin in try fm.contentsOfDirectory(at: pluginsPath, includingPropertiesForKeys: nil) {
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
							rawContent: String(data: data, encoding: .utf8) ?? "",
							isInstalled: false
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

		for configFile in ["settings.json", "settings.local.json"] {
			let fileURL = baseDirectory.appending(path: configFile)
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

		let claudeMD = baseDirectory.appending(path: "CLAUDE.md")
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
	private nonisolated func contentItem(from fileURL: URL, category: ContentCategoryKind, fallbackName: String? = nil, namePrefix: String? = nil, isInstalled: Bool = true) throws -> ContentItem? {
		let content = try String(contentsOf: fileURL, encoding: .utf8)
		let document = FrontmatterDocument(rawContent: content)
		let baseName = document.frontmatter.name ?? fallbackName ?? fileURL.deletingPathExtension().lastPathComponent
		let name = namePrefix.map { "\($0)/\(baseName)" } ?? baseName

		return ContentItem(
			name: name,
			itemDescription: document.frontmatter.description,
			sourceURL: fileURL,
			category: category,
			platformKind: platformKind,
			document: document,
			rawContent: content,
			isInstalled: isInstalled
		)
	}
}
