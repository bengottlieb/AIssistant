//
//  PluginManifest.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/25/26.
//

import Foundation

public struct PluginManifest: Codable, Sendable {
	public let name: String?
	public let description: String?
	public let author: Author?

	public struct Author: Codable, Sendable {
		public let name: String?
		public let email: String?
	}
}
