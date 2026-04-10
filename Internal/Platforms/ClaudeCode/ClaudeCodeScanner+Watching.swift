//
//  ClaudeCodeScanner+Watching.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/26/26.
//

import Foundation

extension ClaudeCodeScanner {
	public var watchedDirectories: [URL] {
		let base = baseDirectory

		switch category {
		case .commands:
			return [base.appending(path: "commands")]
		case .skills:
			return [base.appending(path: "skills"), URL.homeDirectory.appending(path: ".agents/skills"), base.appending(path: "plugins/marketplaces")]
		case .plugins, .agents:
			return [base.appending(path: "plugins/marketplaces")]
		case .mcpServers, .projectConfigs:
			return [base]
		case .sharedClaudeMD:
			return []
		}
	}
}
