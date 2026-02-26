//
//  SidebarView.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import Internal

struct SidebarView: View {
	@Environment(AppViewModel.self) private var viewModel

	var body: some View {
		@Bindable var viewModel = viewModel

		VStack(spacing: 0) {
			Picker("Platform", selection: $viewModel.selectedPlatform) {
				ForEach(PlatformKind.allCases) { platform in
					Text(platform.displayName).tag(platform)
				}
			}
			.pickerStyle(.segmented)
			.padding()

			List(ContentCategoryKind.allCases, selection: $viewModel.selectedCategory) { category in
				Label(category.displayName, systemImage: category.systemImage)
					.tag(category)
			}
		}
		.navigationTitle("AIssistant")
	}
}
