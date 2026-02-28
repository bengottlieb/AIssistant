//
//  DirectoryWatcher.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/26/26.
//

import Foundation

public final class DirectoryWatcher {
	private var sources: [DispatchSourceFileSystemObject] = []
	private var fileDescriptors: [Int32] = []
	private var debounceItem: DispatchWorkItem?
	private let onChange: () -> Void

	public init(directories: [URL], onChange: @escaping () -> Void) {
		self.onChange = onChange

		for directory in directories {
			let fd = open(directory.path(percentEncoded: false), O_EVTONLY)
			guard fd >= 0 else { continue }
			fileDescriptors.append(fd)

			let source = DispatchSource.makeFileSystemObjectSource(
				fileDescriptor: fd,
				eventMask: .write,
				queue: .main
			)

			source.setEventHandler { [weak self] in self?.directoryDidChange() }
			source.setCancelHandler { close(fd) }
			source.resume()
			sources.append(source)
		}
	}

	private func directoryDidChange() {
		debounceItem?.cancel()
		let item = DispatchWorkItem { [weak self] in self?.onChange() }
		debounceItem = item
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: item)
	}

	deinit {
		for source in sources { source.cancel() }
	}
}
