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

	public var id: String { rawValue }

	public var displayName: String {
		switch self {
		case .skills: "Skills"
		case .agents: "Agents"
		case .commands: "Commands"
		case .mcpServers: "MCP Servers"
		case .projectConfigs: "Project Configs"
		}
	}

	public var systemImage: String {
		switch self {
		case .skills: "star.fill"
		case .agents: "person.fill"
		case .commands: "terminal.fill"
		case .mcpServers: "server.rack"
		case .projectConfigs: "gearshape.fill"
		}
	}
}
