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

		List(selection: $viewModel.selectedCategory) {
			Section {
				Picker("Platform", selection: $viewModel.selectedPlatform) {
					ForEach(PlatformKind.allCases) { platform in
						Text(platform.displayName).tag(platform)
					}
				}
				.pickerStyle(.segmented)
				.listRowSeparator(.hidden)
				.listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 4, trailing: 8))
			}

			Section {
				ForEach(ContentCategoryKind.allCases) { category in
					Label(category.displayName, systemImage: category.systemImage)
						.tag(category)
				}
			}
		}
		.listStyle(.sidebar)
		.navigationTitle("AIssistant")
		.safeAreaInset(edge: .bottom) {
			SyncIndicator()
				.padding()
		}
	}
}
