//
//  ContentItem+Cloud.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/1/26.
//

import Foundation

public extension PlatformKind {
	var cloudPrefix: String {
		switch self {
		case .claudeCode: "Claude"
		case .codex: "Codex"
		}
	}

	init?(cloudPrefix: String) {
		switch cloudPrefix {
		case "Claude": self = .claudeCode
		case "Codex": self = .codex
		default: return nil
		}
	}
}

public extension ContentItem {
	var cloudRecordName: String {
		"\(platformKind.cloudPrefix)/\(cloudRelativePath)"
	}

	var cloudRelativePath: String {
		let base = platformKind.baseDirectory.path(percentEncoded: false)
		return sourceURL.path(percentEncoded: false)
			.replacingOccurrences(of: base + "/", with: "")
	}
}
