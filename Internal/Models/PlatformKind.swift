//
//  PlatformKind.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/25/26.
//

import Foundation

public enum PlatformKind: String, CaseIterable, Identifiable, Codable, Sendable {
	case claudeCode
	case codex

	public var id: String { rawValue }

	public var displayName: String {
		switch self {
		case .claudeCode: "Claude Code"
		case .codex: "OpenAI Codex"
		}
	}

	public var iconSystemName: String {
		switch self {
		case .claudeCode: "brain.head.profile"
		case .codex: "book.closed"
		}
	}

	public var baseDirectory: URL {
		switch self {
		case .claudeCode: URL.homeDirectory.appending(path: ".claude")
		case .codex: URL.homeDirectory.appending(path: ".codex")
		}
	}

	public func scanner(for category: ContentCategoryKind) -> any PlatformScanner {
		switch self {
		case .claudeCode: ClaudeCodeScanner(category: category)
		case .codex: CodexScanner(category: category)
		}
	}
}
