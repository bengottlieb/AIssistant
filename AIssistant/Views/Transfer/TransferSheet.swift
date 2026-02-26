//
//  TransferSheet.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import Internal

struct TransferSheet: View {
	let item: ContentItem

	@Environment(\.dismiss) private var dismiss
	@State private var targetPlatform: PlatformKind = .codex
	@State private var transferError: String?
	@State private var transferSuccess = false

	var body: some View {
		VStack(spacing: 20) {
			Text("Transfer \"\(item.name)\"")
				.font(.headline)

			Picker("Target Platform", selection: $targetPlatform) {
				ForEach(availablePlatforms) { platform in
					Text(platform.displayName).tag(platform)
				}
			}
			.pickerStyle(.segmented)

			GroupBox("Destination") {
				Text(destinationPath)
					.font(.system(.caption, design: .monospaced))
					.textSelection(.enabled)
					.frame(maxWidth: .infinity, alignment: .leading)
			}

			if let error = transferError {
				Text(error)
					.font(.caption)
					.foregroundStyle(.red)
			}

			if transferSuccess {
				Label("Transfer complete!", systemImage: "checkmark.circle.fill")
					.foregroundStyle(.green)
			}

			HStack {
				Button("Cancel") {
					dismiss()
				}
				.keyboardShortcut(.cancelAction)

				Button("Transfer") {
					performTransfer()
				}
				.keyboardShortcut(.defaultAction)
				.disabled(transferSuccess)
			}
		}
		.padding(24)
		.frame(minWidth: 400)
		.onAppear {
			// Default to the other platform
			targetPlatform = item.platformKind == .claudeCode ? .codex : .claudeCode
		}
	}

	private var availablePlatforms: [PlatformKind] {
		PlatformKind.allCases.filter { $0 != item.platformKind }
	}

	private var destinationPath: String {
		TransferService.destinationURL(for: item, in: targetPlatform)
			.path(percentEncoded: false)
			.replacingOccurrences(of: NSHomeDirectory(), with: "~")
	}

	private func performTransfer() {
		transferError = nil
		let currentItem = item
		let platform = targetPlatform
		let result: URL? = report("Transferring \(currentItem.name) to \(platform.displayName)") {
			try TransferService.transfer(currentItem, to: platform)
		}
		if result != nil {
			transferSuccess = true
		} else {
			transferError = "Transfer failed. Check the error log in Settings."
		}
	}
}
