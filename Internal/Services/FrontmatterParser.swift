//
//  FrontmatterParser.swift
//  Internal
//
//  Created by Ben Gottlieb on 2/25/26.
//

import Foundation

public enum FrontmatterParser {
	public struct Result: Sendable {
		public let frontmatter: Frontmatter
		public let body: String
	}

	public static func parse(_ content: String) -> Result {
		let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

		guard trimmed.hasPrefix("---") else {
			return Result(frontmatter: Frontmatter(), body: content)
		}

		let lines = content.components(separatedBy: .newlines)
		var frontmatterLines: [String] = []
		var foundOpeningDelimiter = false
		var closingIndex: Int?

		for (index, line) in lines.enumerated() {
			let stripped = line.trimmingCharacters(in: .whitespaces)

			if stripped == "---" {
				if !foundOpeningDelimiter {
					foundOpeningDelimiter = true
					continue
				} else {
					closingIndex = index
					break
				}
			}

			if foundOpeningDelimiter {
				frontmatterLines.append(line)
			}
		}

		guard let endIndex = closingIndex else {
			return Result(frontmatter: Frontmatter(), body: content)
		}

		let fields = parseFrontmatterFields(frontmatterLines)
		let bodyLines = Array(lines[(endIndex + 1)...])
		let body = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

		return Result(frontmatter: Frontmatter(fields: fields), body: body)
	}

	private static func parseFrontmatterFields(_ lines: [String]) -> [String: String] {
		var fields: [String: String] = [:]

		for line in lines {
			let trimmed = line.trimmingCharacters(in: .whitespaces)
			guard !trimmed.isEmpty else { continue }

			guard let colonIndex = trimmed.firstIndex(of: ":") else { continue }

			let key = String(trimmed[trimmed.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
			var value = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

			// Strip surrounding quotes
			if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
				(value.hasPrefix("'") && value.hasSuffix("'")) {
				value = String(value.dropFirst().dropLast())
			}

			guard !key.isEmpty else { continue }
			fields[key] = value
		}

		return fields
	}
}
