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
		var index = 0

		while index < lines.count {
			let line = lines[index]
			let trimmed = line.trimmingCharacters(in: .whitespaces)
			guard !trimmed.isEmpty, let colonIndex = trimmed.firstIndex(of: ":") else {
				index += 1
				continue
			}

			let key = String(trimmed[trimmed.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
			var value = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

			// Handle YAML block scalars (| for literal, > for folded)
			if value == "|" || value == ">" {
				let fold = value == ">"
				var blockLines: [String] = []
				index += 1

				// Collect indented continuation lines
				while index < lines.count {
					let nextLine = lines[index]
					let nextTrimmed = nextLine.trimmingCharacters(in: .whitespaces)
					let isIndented = nextLine.hasPrefix(" ") || nextLine.hasPrefix("\t")

					if nextTrimmed.isEmpty {
						blockLines.append("")
						index += 1
					} else if isIndented {
						blockLines.append(nextTrimmed)
						index += 1
					} else {
						break
					}
				}

				// Trim trailing empty lines
				while blockLines.last?.isEmpty == true { blockLines.removeLast() }

				value = fold ? blockLines.joined(separator: " ") : blockLines.joined(separator: "\n")
			} else {
				// Strip surrounding quotes
				if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
					(value.hasPrefix("'") && value.hasSuffix("'")) {
					value = String(value.dropFirst().dropLast())
				}
				index += 1
			}

			guard !key.isEmpty else { continue }
			fields[key] = value
		}

		return fields
	}
}
