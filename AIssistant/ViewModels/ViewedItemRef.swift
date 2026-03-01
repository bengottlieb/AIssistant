//
//  ViewedItemRef.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 3/1/26.
//

import Foundation
import Internal

struct ViewedItemRef: Codable, Equatable, Identifiable {
	let sourceURL: URL
	let platformKind: PlatformKind
	let category: ContentCategoryKind
	let name: String

	var id: URL { sourceURL }
}
