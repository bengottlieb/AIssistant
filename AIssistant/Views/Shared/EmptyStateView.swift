//
//  EmptyStateView.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 2/25/26.
//

import SwiftUI

struct EmptyStateView: View {
	let message: String
	var systemImage: String = "tray"

	var body: some View {
		ContentUnavailableView {
			Label(message, systemImage: systemImage)
		}
	}
}
