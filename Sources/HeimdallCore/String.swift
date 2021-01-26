/**
 *  Heimdall
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

extension String {
	// Thanks to: https://stackoverflow.com/a/49547114
	func count(of needle: Character) -> Int {
		return reduce(0) {
			return $1 == needle ? $0 + 1 : $0
		}
	}

	var titleified: String {
		return self
			.replacingOccurrences(of: "_", with: " ")
			.capitalized
	}
}
