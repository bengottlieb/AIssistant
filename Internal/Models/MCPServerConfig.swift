//
//  MCPServerConfig.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/25/26.
//

import Foundation

public struct MCPServerConfig: Codable, Sendable {
	public let mcpServers: [String: ServerEntry]?

	public struct ServerEntry: Codable, Sendable {
		public let type: String?
		public let url: String?
		public let command: String?
		public let args: [String]?
	}
}
