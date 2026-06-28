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
				ForEach(ContentCategoryKind.sidebarCategories) { category in
					Label(category.displayName, systemImage: category.systemImage)
						.tag(category)
				}
			}

			Section {
				Label("CLAUDE.md", systemImage: ContentCategoryKind.sharedClaudeMD.systemImage)
					.tag(ContentCategoryKind.sharedClaudeMD)
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
			VStack(spacing: 8) {
				HStack(spacing: 6) {
					Image(systemName: "line.3.horizontal.decrease.circle")
						.foregroundStyle(.secondary)
					TextField("Filter", text: $viewModel.filterText)
						.textFieldStyle(.plain)
					if !viewModel.filterText.isEmpty {
						Button {
							viewModel.filterText = ""
						} label: {
							Image(systemName: "xmark.circle.fill")
								.foregroundStyle(.secondary)
						}
						.buttonStyle(.plain)
					}
				}
				.padding(.horizontal, 8)
				.padding(.vertical, 6)
				.background(.quaternary, in: .rect(cornerRadius: 8))

				SyncIndicator()
			}
			.padding()
		}
	}
}
