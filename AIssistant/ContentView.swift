//
//  ContentView.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI
import Internal

struct ContentView: View {
	@State private var viewModel = AppViewModel()
	@State private var cloudCache = CloudStatusCache()

	var body: some View {
		NavigationSplitView {
			SidebarView()
		} content: {
			if let category = viewModel.selectedCategory {
				ContentListView(platform: viewModel.selectedPlatform, category: category)
			} else {
				EmptyStateView(message: "Select a category")
			}
		} detail: {
			if let item = viewModel.selectedItem {
				DetailView(item: item)
			} else {
				EmptyStateView(message: "Select an item to view details")
			}
		}
		.environment(viewModel)
		.environment(cloudCache)
		.task {
			await CloudSyncService.shared.setup()
		}
	}
}

#Preview {
	ContentView()
}
