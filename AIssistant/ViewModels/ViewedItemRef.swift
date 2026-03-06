//
//  ViewedItemRef.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 3/1/26.
//

import Foundation
import Internal

struct ViewedItemRef: Equatable, Identifiable, Sendable {
	let sourceURL: URL
	let platformKind: PlatformKind
	let category: ContentCategoryKind
	let name: String

	var id: URL { sourceURL }
}

extension ViewedItemRef: Codable {
	nonisolated init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		sourceURL = try container.decode(URL.self, forKey: .sourceURL)
		platformKind = try container.decode(PlatformKind.self, forKey: .platformKind)
		category = try container.decode(ContentCategoryKind.self, forKey: .category)
		name = try container.decode(String.self, forKey: .name)
	}

	nonisolated func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(sourceURL, forKey: .sourceURL)
		try container.encode(platformKind, forKey: .platformKind)
		try container.encode(category, forKey: .category)
		try container.encode(name, forKey: .name)
	}

	private enum CodingKeys: String, CodingKey {
		case sourceURL, platformKind, category, name
	}
}
