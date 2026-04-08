//
//  ContentItemRow+SkillInstall.swift
//  AIssistant
//

import SwiftUI
import AppKit
import Internal

extension Notification.Name {
	static let skillInstallStateChanged = Notification.Name("com.aissistant.skillInstallStateChanged")
}

extension ContentItemRow {
	var userSkillsDirectory: URL {
		item.platformKind.baseDirectory.appending(path: "skills")
	}

	private var skillFolderName: String {
		item.sourceURL.deletingLastPathComponent().lastPathComponent
	}

	func installSkill() {
		let fm = FileManager.default
		let sourceFolder = item.sourceURL.deletingLastPathComponent()
		let destination = userSkillsDirectory.appending(path: skillFolderName)

		do {
			try fm.createDirectory(at: userSkillsDirectory, withIntermediateDirectories: true)
			if fm.fileExists(atPath: destination.path(percentEncoded: false)) {
				try fm.removeItem(at: destination)
			}
			try fm.copyItem(at: sourceFolder, to: destination)
			NotificationCenter.default.post(name: .skillInstallStateChanged, object: nil)
		} catch {
			NSAlert(error: error).runModal()
		}
	}

	func uninstallSkill() {
		let installedFolder = item.sourceURL.deletingLastPathComponent()
		do {
			try FileManager.default.removeItem(at: installedFolder)
			NotificationCenter.default.post(name: .skillInstallStateChanged, object: nil)
		} catch {
			NSAlert(error: error).runModal()
		}
	}
}
