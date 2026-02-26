//
//  FrontmatterDocument.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/25/26.
//

import Foundation

public struct FrontmatterDocument: Sendable, Hashable {
	public let frontmatter: Frontmatter
	public let body: String
	public let rawContent: String

	public init(rawContent: String) {
		self.rawContent = rawContent
		let parsed = FrontmatterParser.parse(rawContent)
		self.frontmatter = parsed.frontmatter
		self.body = parsed.body
	}

	public init(frontmatter: Frontmatter, body: String, rawContent: String) {
		self.frontmatter = frontmatter
		self.body = body
		self.rawContent = rawContent
	}
}
