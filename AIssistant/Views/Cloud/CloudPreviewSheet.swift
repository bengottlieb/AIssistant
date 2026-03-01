//
//  CloudPreviewSheet.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 3/1/26.
//

import SwiftUI
import Internal

extension Notification.Name {
	static let cloudReplacedLocalFile = Notification.Name("cloudReplacedLocalFile")
}

struct CloudPreviewSheet: View {
	let item: ContentItem

	@Environment(\.dismiss) private var dismiss
	@Environment(CloudStatusCache.self) private var cloudCache
	@State private var diff: DiffComputer.Result?

	var body: some View {
		VStack(spacing: 0) {
			Text("Compare: \"\(item.name)\"")
				.font(.headline)
				.padding()

			Divider()

			HStack(spacing: 0) {
				Text("Local").paneHeader()
				Divider()
				Text("Cloud").paneHeader()
			}
			.frame(height: 28)

			Divider()

			if let diff {
				ScrollView {
					LazyVStack(spacing: 0) {
						ForEach(Array(zip(diff.local, diff.cloud).enumerated()), id: \.offset) { _, pair in
							HStack(spacing: 0) {
								diffLine(pair.0)
								Divider()
								diffLine(pair.1)
							}
						}
					}
				}
			} else {
				ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
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
		.frame(minWidth: 960, minHeight: 680)
		.task {
			let cloudText = cloudCache.cloudContent(for: item) ?? ""
			diff = DiffComputer.compute(local: item.rawContent, cloud: cloudText)
		}
	}

	@ViewBuilder
	private func diffLine(_ line: DiffComputer.Line) -> some View {
		let styled = Text(line.status == .empty ? " " : line.text)
			.font(.system(.body, design: .monospaced))
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.horizontal, 8)
			.padding(.vertical, 2)
			.background(lineBackground(line.status))
		if line.status != .empty {
			styled.textSelection(.enabled)
		} else {
			styled
		}
	}

	private func lineBackground(_ status: DiffComputer.LineStatus) -> Color {
		switch status {
		case .unchanged: .clear
		case .changed: .yellow.opacity(0.3)
		case .empty: Color.gray.opacity(0.08)
		}
	}

	private func replaceLocalWithCloud() {
		guard let cloudContent = cloudCache.cloudContent(for: item) else { return }
		try? cloudContent.write(to: item.sourceURL, atomically: true, encoding: .utf8)
		NotificationCenter.default.post(name: .cloudReplacedLocalFile, object: item.sourceURL, userInfo: ["content": cloudContent])
	}
}

private extension Text {
	func paneHeader() -> some View {
		self
			.font(.caption.bold())
			.foregroundStyle(.secondary)
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.horizontal, 8)
			.padding(.vertical, 6)
	}
}
