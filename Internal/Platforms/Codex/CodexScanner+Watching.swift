//
//  CodexScanner+Watching.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/26/26.
//

import Foundation

extension CodexScanner {
	public var watchedDirectories: [URL] {
		switch category {
		case .skills:
			return [
				baseDirectory.appending(path: "skills"),
				baseDirectory.appending(path: "vendor_imports/skills/skills/.curated")
			]
		case .agents:
			return [baseDirectory.appending(path: "vendor_imports/skills/skills/.curated")]
		case .commands, .mcpServers, .projectConfigs:
			return []
		}
	}
}
