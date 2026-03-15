//
//  ContentCategoryKind.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/25/26.
//

import Foundation

public enum ContentCategoryKind: String, CaseIterable, Identifiable, Codable, Sendable {
	case skills
	case agents
	case commands
	case mcpServers
	case projectConfigs
	case sharedClaudeMD

	public var id: String { rawValue }

	/// Categories shown in the main sidebar list (excludes special items).
	public static var sidebarCategories: [ContentCategoryKind] {
		allCases.filter { $0 != .sharedClaudeMD }
	}

	public var displayName: String {
		switch self {
		case .skills: "Skills"
		case .agents: "Agents"
		case .commands: "Commands"
		case .mcpServers: "MCP Servers"
		case .projectConfigs: "Project Configs"
		case .sharedClaudeMD: "CLAUDE.md"
		}
	}

	public var systemImage: String {
		switch self {
		case .skills: "star.fill"
		case .agents: "person.fill"
		case .commands: "terminal.fill"
		case .mcpServers: "server.rack"
		case .projectConfigs: "gearshape.fill"
		case .sharedClaudeMD: "doc.text"
		}
	}
}
