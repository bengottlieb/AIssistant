//
//  MarkdownEditorView.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import AppKit

struct MarkdownEditorView: View {
	@Binding var content: String

	var body: some View {
		PlainTextEditor(text: $content)
	}
}

private struct PlainTextEditor: NSViewRepresentable {
	@Binding var text: String

	func makeNSView(context: Context) -> NSScrollView {
		let scrollView = NSTextView.scrollableTextView()
		let textView = scrollView.documentView as! NSTextView

		textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
		textView.isAutomaticQuoteSubstitutionEnabled = false
		textView.isAutomaticDashSubstitutionEnabled = false
		textView.isAutomaticTextReplacementEnabled = false
		textView.isAutomaticSpellingCorrectionEnabled = false
		textView.isRichText = false
		textView.allowsUndo = true
		textView.usesFindBar = true
		textView.isEditable = true
		textView.isSelectable = true
		textView.textContainerInset = NSSize(width: 4, height: 8)
		textView.delegate = context.coordinator
		textView.string = text

		return scrollView
	}

	func updateNSView(_ nsView: NSScrollView, context: Context) {
		guard let textView = nsView.documentView as? NSTextView else { return }
		if textView.string != text, !context.coordinator.isEditing {
			textView.string = text
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(text: $text)
	}

	class Coordinator: NSObject, NSTextViewDelegate {
		var text: Binding<String>
		var isEditing = false

		init(text: Binding<String>) {
			self.text = text
		}

		func textDidBeginEditing(_ notification: Notification) {
			isEditing = true
		}

		func textDidEndEditing(_ notification: Notification) {
			isEditing = false
		}

		func textDidChange(_ notification: Notification) {
			guard let textView = notification.object as? NSTextView else { return }
			text.wrappedValue = textView.string
		}
	}
}
