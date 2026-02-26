//
//  MarkdownPreviewView.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import MarkdownUI

struct MarkdownPreviewView: View {
	let markdown: String

	var body: some View {
		ScrollView {
			Markdown(markdown)
				.textSelection(.enabled)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding()
		}
	}
}
