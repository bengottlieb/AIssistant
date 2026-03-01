//
//  AppViewModel.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import Internal

@Observable
class AppViewModel {
	var selectedPlatform: PlatformKind {
		didSet { UserDefaults.standard.setCodable(selectedPlatform, forKey: "selectedPlatform") }
	}
	var selectedCategory: ContentCategoryKind?
	var selectedItem: ContentItem? {
		didSet { if let item = selectedItem { addToHistory(item) } }
	}
	var recentItems: [ViewedItemRef] = []
	var pendingSelectionURL: URL?

	init() {
		let savedHistory = UserDefaults.standard.codable([ViewedItemRef].self, forKey: "viewHistory") ?? []
		let defaultPlatform = UserDefaults.standard.codable(PlatformKind.self, forKey: "selectedPlatform") ?? .claudeCode

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
		UserDefaults.standard.setCodable(recentItems, forKey: "viewHistory")
	}
}

extension UserDefaults {
	func setCodable<T: Encodable>(_ value: T, forKey key: String) {
		if let data = try? JSONEncoder().encode(value) {
			set(data, forKey: key)
		}
	}

	func codable<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
		guard let data = data(forKey: key) else { return nil }
		return try? JSONDecoder().decode(type, from: data)
	}
}
