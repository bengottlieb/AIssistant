//
//  ContentItemRow.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import AppKit
import Internal

struct ContentItemRow: View {
	let item: ContentItem

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			HStack {
				Text(item.name)
					.font(.headline)
				Spacer()
				CloudIndicator(item: item)
			}

			if let description = item.itemDescription {
				Text(description)
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.lineLimit(2)
			}

			Text(item.relativePath)
				.font(.caption)
				.foregroundStyle(.tertiary)
				.lineLimit(1)
		}
		.padding(.vertical, 2)
		.contextMenu {
			Button("Reveal in Finder") {
				NSWorkspace.shared.activateFileViewerSelecting([item.sourceURL])
			}

			Button("Copy Path") {
				NSPasteboard.general.clearContents()
				NSPasteboard.general.setString(item.sourceURL.path(percentEncoded: false), forType: .string)
			}

			Divider()

			Button("Open in Default Editor") {
				NSWorkspace.shared.open(item.sourceURL)
			}

			if item.category == .commands {
				Divider()

				if isInUserCommandsDirectory {
					Button("Deactivate Command") {
						deactivateCommand()
					}
				} else {
					Button("Activate Command") {
						activateCommand()
					}
				}
			}
		}
	}

	private var userCommandsDirectory: URL {
		item.platformKind.baseDirectory.appending(path: "commands")
	}

	private var isInUserCommandsDirectory: Bool {
		item.sourceURL.deletingLastPathComponent().standardizedFileURL
			== userCommandsDirectory.standardizedFileURL
	}

	private static let originAttributeName = "com.aissistant.originalPath"

	private func activateCommand() {
		let fm = FileManager.default
		let destination = userCommandsDirectory.appending(path: item.sourceURL.lastPathComponent)

		do {
			try fm.createDirectory(at: userCommandsDirectory, withIntermediateDirectories: true)
			try fm.moveItem(at: item.sourceURL, to: destination)

			let originData = Data(item.sourceURL.path(percentEncoded: false).utf8)
			try destination.setExtendedAttribute(Self.originAttributeName, data: originData)
		} catch {
			let alert = NSAlert(error: error)
			alert.runModal()
		}
	}

	private func deactivateCommand() {
		let fm = FileManager.default

		do {
			let originData = try item.sourceURL.extendedAttribute(Self.originAttributeName)
			let originalPath = String(decoding: originData, as: UTF8.self)
			let originalURL = URL(filePath: originalPath)

			try fm.createDirectory(at: originalURL.deletingLastPathComponent(), withIntermediateDirectories: true)
			try fm.moveItem(at: item.sourceURL, to: originalURL)
		} catch {
			let alert = NSAlert(error: error)
			alert.runModal()
		}
	}
}
