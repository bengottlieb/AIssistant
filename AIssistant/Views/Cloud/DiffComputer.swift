//
//  DiffComputer.swift
//  AIssistant
//
//  Created by Ben Gottlieb on 3/1/26.
//

import Foundation

struct DiffComputer {
	enum LineStatus { case unchanged, changed, empty }

	struct Line: Identifiable {
		let id = UUID()
		let text: String
		let status: LineStatus
	}

	struct Result {
		let local: [Line]
		let cloud: [Line]
	}

	static func compute(local localText: String, cloud cloudText: String) -> Result {
		let a = localText.components(separatedBy: "\n")
		let b = cloudText.components(separatedBy: "\n")
		let dp = lcsTable(a, b)
		var left: [Line] = []
		var right: [Line] = []
		backtrack(a, b, dp, a.count, b.count, &left, &right)
		return Result(local: left, cloud: right)
	}

	private static func lcsTable(_ a: [String], _ b: [String]) -> [[Int]] {
		let m = a.count, n = b.count
		var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
		guard m > 0, n > 0 else { return dp }
		for i in 1...m {
			for j in 1...n {
				dp[i][j] = a[i-1] == b[j-1] ? dp[i-1][j-1] + 1 : max(dp[i-1][j], dp[i][j-1])
			}
		}
		return dp
	}

	private static func backtrack(_ a: [String], _ b: [String], _ dp: [[Int]], _ i: Int, _ j: Int, _ left: inout [Line], _ right: inout [Line]) {
		if i == 0 && j == 0 { return }
		if i > 0 && j > 0 && a[i-1] == b[j-1] {
			backtrack(a, b, dp, i-1, j-1, &left, &right)
			left.append(Line(text: a[i-1], status: .unchanged))
			right.append(Line(text: b[j-1], status: .unchanged))
		} else if j > 0 && (i == 0 || dp[i][j-1] >= dp[i-1][j]) {
			backtrack(a, b, dp, i, j-1, &left, &right)
			left.append(Line(text: "", status: .empty))
			right.append(Line(text: b[j-1], status: .changed))
		} else {
			backtrack(a, b, dp, i-1, j, &left, &right)
			left.append(Line(text: a[i-1], status: .changed))
			right.append(Line(text: "", status: .empty))
		}
	}
}
