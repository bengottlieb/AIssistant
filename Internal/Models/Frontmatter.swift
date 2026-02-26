//
//  Frontmatter.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/25/26.
//

import Foundation

public struct Frontmatter: Sendable, Hashable {
	public var fields: [String: String]

	public init(fields: [String: String] = [:]) {
		self.fields = fields
	}

	public var name: String? { fields["name"] }
	public var description: String? { fields["description"] }
	public var version: String? { fields["version"] }
	public var model: String? { fields["model"] }
	public var tools: String? { fields["tools"] }
	public var argumentHint: String? { fields["argument_hint"] ?? fields["argumentHint"] }
	public var allowedTools: String? { fields["allowed_tools"] ?? fields["allowedTools"] ?? fields["allowed-tools"] }
}
