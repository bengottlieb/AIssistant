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
	var selectedItem: ContentItem?

	init() {
		self.selectedPlatform = UserDefaults.standard.codable(PlatformKind.self, forKey: "selectedPlatform") ?? .claudeCode
	}
}

private extension UserDefaults {
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
