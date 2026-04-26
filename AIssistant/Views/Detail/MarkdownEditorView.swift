//
//  MarkdownEditorView.swift
//  AIssistant
//

import SwiftUI
import MarkDownRange

struct MarkdownEditorView: View {
	@Binding var content: String
	@State private var selectedHeadingID: String? = nil

	var body: some View {
		RawMarkdownScreen(
			text: $content,
			selectedHeadingID: $selectedHeadingID,
			fontSize: 13
		)
	}
}
