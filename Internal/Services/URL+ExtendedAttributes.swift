//
//  URL+ExtendedAttributes.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/26/26.
//

import Foundation

public extension URL {
	func extendedAttribute(_ name: String) throws -> Data {
		let path = self.path(percentEncoded: false)

		let length = getxattr(path, name, nil, 0, 0, 0)
		guard length >= 0 else {
			throw CocoaError(.fileReadUnknown)
		}

		var data = Data(count: length)
		let result = data.withUnsafeMutableBytes {
			getxattr(path, name, $0.baseAddress, length, 0, 0)
		}
		guard result >= 0 else {
			throw CocoaError(.fileReadUnknown)
		}

		return data
	}

	func setExtendedAttribute(_ name: String, data: Data) throws {
		let path = self.path(percentEncoded: false)

		let result = data.withUnsafeBytes {
			setxattr(path, name, $0.baseAddress, data.count, 0, 0)
		}
		guard result >= 0 else {
			throw CocoaError(.fileWriteUnknown)
		}
	}
}
