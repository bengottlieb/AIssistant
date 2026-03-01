//
//  CloudPreviewSheet.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 3/1/26.
//

import SwiftUI
import Internal

struct CloudPreviewSheet: View {
	let item: ContentItem

	@Environment(\.dismiss) private var dismiss
	@Environment(CloudStatusCache.self) private var cloudCache

	var body: some View {
		VStack(spacing: 0) {
			Text("Compare: \"\(item.name)\"")
				.font(.headline)
				.padding()

			Divider()

			HSplitView {
				VStack(alignment: .leading) {
					Text("Local")
						.font(.caption)
						.foregroundStyle(.secondary)
						.padding(.horizontal)
						.padding(.top, 8)

					ScrollView {
						Text(item.rawContent)
							.font(.system(.body, design: .monospaced))
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding()
							.textSelection(.enabled)
					}
				}

				VStack(alignment: .leading) {
					Text("Cloud")
						.font(.caption)
						.foregroundStyle(.secondary)
						.padding(.horizontal)
						.padding(.top, 8)

					ScrollView {
						Text(cloudCache.cloudContent(for: item) ?? "No cloud content")
							.font(.system(.body, design: .monospaced))
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding()
							.textSelection(.enabled)
					}
				}
			}

			Divider()

			HStack {
				Button("Replace Cloud with Local") {
					CloudSyncService.shared.upload(item)
					dismiss()
				}

				Spacer()

				Button("Replace Local with Cloud") {
					replaceLocalWithCloud()
					dismiss()
				}

				Spacer()

				Button("Done") { dismiss() }
					.keyboardShortcut(.cancelAction)
			}
			.padding()
		}
		.frame(minWidth: 600, minHeight: 400)
	}

	private func replaceLocalWithCloud() {
		guard let cloudContent = cloudCache.cloudContent(for: item) else { return }
		try? cloudContent.write(to: item.sourceURL, atomically: true, encoding: .utf8)
	}
}
