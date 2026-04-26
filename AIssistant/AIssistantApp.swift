//
//  AIssistantApp.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import AppKit
import Internal
import Chronicle

@main
struct AIssistantApp: App {
    init() {
        Chronicle.instance.setupSyncEngine()
    }
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
		.defaultSize(width: 1000, height: 650)
		.commands {
			ChronicleCommands()
			CloudCommands()
			EditorCommands()
		}

		Window("SyncEngine Chronicle", id: "chronicle") {
			ChronicleScreen()
		}
		.defaultSize(width: 800, height: 600)

		Settings {
		}
	}
}

struct ChronicleCommands: Commands {
	@Environment(\.openWindow) private var openWindow

	var body: some Commands {
		CommandGroup(after: .windowArrangement) {
			Button("SyncEngine Chronicle") {
				openWindow(id: "chronicle")
			}
			.keyboardShortcut("L", modifiers: [.command, .shift])
		}
	}
}

struct EditorCommands: Commands {
	var body: some Commands {
		CommandMenu("Editor") {
			Toggle("Show Line Numbers", isOn: Binding(
				get: { EditorSettings.shared.showLineNumbers },
				set: { EditorSettings.shared.showLineNumbers = $0 }
			))
			.keyboardShortcut("L", modifiers: [.command, .option])

			Toggle("Syntax Highlighting", isOn: Binding(
				get: { EditorSettings.shared.syntaxHighlightingEnabled },
				set: { EditorSettings.shared.syntaxHighlightingEnabled = $0 }
			))
			.keyboardShortcut("H", modifiers: [.command, .option])
		}
	}
}

struct CloudCommands: Commands {
	var body: some Commands {
		CommandGroup(after: .saveItem) {
			Button("Update All Local Files from Cloud…") {
				Task { @MainActor in
					let result = CloudSyncService.shared.writeAllToLocalDisk()
					let alert = NSAlert()
					alert.messageText = "Updated Local Files"
					alert.informativeText = "Wrote \(result.written) file(s) from iCloud." + (result.failed > 0 ? " \(result.failed) failed." : "")
					alert.runModal()
				}
			}
		}
	}
}
