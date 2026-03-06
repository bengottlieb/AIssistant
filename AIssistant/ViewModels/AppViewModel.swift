//
//  AppViewModel.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import Internal
import SharedSettings

struct SelectedPlatformKey: SettingsKey {
	static let defaultValue: PlatformKind = .claudeCode
	static let name = "selectedPlatform"
}

struct ViewHistoryKey: SettingsKey {
	static let defaultValue: [ViewedItemRef] = []
	static let name = "viewHistory"
}

@Observable
class AppViewModel {
	var selectedPlatform: PlatformKind {
		didSet { SelectedPlatformKey.sharedValue = selectedPlatform }
	}
	var selectedCategory: ContentCategoryKind?
	var selectedItem: ContentItem? {
		didSet { if let item = selectedItem { addToHistory(item) } }
	}
	var recentItems: [ViewedItemRef] = []
	var pendingSelectionURL: URL?

	init() {
		let savedHistory = ViewHistoryKey.sharedValue
		let defaultPlatform = SelectedPlatformKey.sharedValue

		self.selectedPlatform = savedHistory.first?.platformKind ?? defaultPlatform
		self.recentItems = savedHistory

		if let first = savedHistory.first {
			self.selectedCategory = first.category
			self.pendingSelectionURL = first.sourceURL
		}
	}

	func navigateTo(_ ref: ViewedItemRef) {
		selectedPlatform = ref.platformKind
		selectedCategory = ref.category
		pendingSelectionURL = ref.sourceURL
	}

	private func addToHistory(_ item: ContentItem) {
		let ref = ViewedItemRef(sourceURL: item.sourceURL, platformKind: item.platformKind, category: item.category, name: item.name)
		recentItems.removeAll { $0.sourceURL == item.sourceURL }
		recentItems.insert(ref, at: 0)
		if recentItems.count > 50 { recentItems.removeLast() }
		ViewHistoryKey.sharedValue = recentItems
	}
}
