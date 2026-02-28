//
//  ClaudeCodeScanner+Watching.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/26/26.
//

import Foundation

extension ClaudeCodeScanner {
	public var watchedDirectories: [URL] {
		let base = platformKind.baseDirectory

		switch category {
		case .commands:
			return [base.appending(path: "commands")]
		case .skills, .agents:
			return [base.appending(path: "plugins/marketplaces")]
		case .mcpServers, .projectConfigs:
			return [base]
		}
	}
}
