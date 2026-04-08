//
//  AIssistantApp.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
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
