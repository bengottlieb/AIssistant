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
				.labelsHidden()
				.pickerStyle(.segmented)
				.listRowSeparator(.hidden)
				.listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 4, trailing: 8))
				.frame(maxWidth: .infinity, alignment: .center)
			}

			Section {
				ForEach(ContentCategoryKind.allCases) { category in
					Label(category.displayName, systemImage: category.systemImage)
						.tag(category)
				}
			}

			if !viewModel.recentItems.isEmpty {
				Section("Recents") {
					ForEach(viewModel.recentItems.prefix(10)) { ref in
						Button {
							viewModel.navigateTo(ref)
						} label: {
							Label(ref.name, systemImage: ref.category.systemImage)
								.lineLimit(1)
						}
						.buttonStyle(.plain)
					}
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
