//
//  EditorSettings.swift
//  AIssistant
//

import SwiftUI
import SharedSettings

struct ShowLineNumbersKey: SettingsKey {
	static let defaultValue = false
	static let name = "showLineNumbers"
}

struct SyntaxHighlightingKey: SettingsKey {
	static let defaultValue = false
	static let name = "syntaxHighlightingEnabled"
}

@Observable final class EditorSettings {
	static let shared = EditorSettings()

	var showLineNumbers: Bool {
		didSet { ShowLineNumbersKey.sharedValue = showLineNumbers }
	}
	var syntaxHighlightingEnabled: Bool {
		didSet { SyntaxHighlightingKey.sharedValue = syntaxHighlightingEnabled }
	}

	private init() {
		showLineNumbers = ShowLineNumbersKey.sharedValue
		syntaxHighlightingEnabled = SyntaxHighlightingKey.sharedValue
	}
}
