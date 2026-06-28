//
//  ContentItem+Bundle.swift
//  Internal
//
//  Created by Ben Gottlieb on 6/28/26.
//

import Foundation

public extension ContentItem {
	/// The folder that constitutes this item's bundle, or nil for single-file
	/// items. Skills are rooted at the folder containing SKILL.md; plugins at
	/// the plugin directory (whose sourceURL is the dir itself or its README.md).
	var bundleRootURL: URL? {
		if isSkillBundle { return sourceURL.deletingLastPathComponent() }
		if category == .plugins {
			var isDirectory: ObjCBool = false
			let exists = FileManager.default.fileExists(atPath: sourceURL.path(percentEncoded: false), isDirectory: &isDirectory)
			return (exists && isDirectory.boolValue) ? sourceURL : sourceURL.deletingLastPathComponent()
		}
		return nil
	}

	/// True when this item is backed by a folder of files (skill or plugin)
	/// rather than a single markdown/JSON file.
	var isFolderBundle: Bool { bundleRootURL != nil }
}
