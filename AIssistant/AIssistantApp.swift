//
//  AIssistantApp.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import Internal

@main
struct AIssistantApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
		.defaultSize(width: 1000, height: 650)

		Settings {
			PaperOfRecordView()
				.frame(minWidth: 500, minHeight: 400)
		}
	}
}
