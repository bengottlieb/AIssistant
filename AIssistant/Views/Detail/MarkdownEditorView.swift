//
//  MarkdownEditorView.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI

struct MarkdownEditorView: View {
	@Binding var content: String

	var body: some View {
		TextEditor(text: $content)
			.font(.system(.body, design: .monospaced))
			.scrollContentBackground(.visible)
	}
}
