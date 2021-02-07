/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

extension String {

    /// Return the amount of times a character appears in the string.
	/// Thanks to: https://stackoverflow.com/a/49547114
    ///
    /// - Parameter of: Character to look for.
    /// - Returns: Amount of times the character appears.
	func count(of needle: Character) -> Int {
		return reduce(0) {
			return $1 == needle ? $0 + 1 : $0
		}
	}
    
    /// Remove the suffix (if it exists).
    ///
    /// - Parameter suffix: Suffix to remove.
    /// - Returns: String with the suffix removed.
    func trimSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        
        return String(dropLast(suffix.count))
    }

    /// Titleified version of the string, replacing _ with spaces and capitalizing.
	var titleified: String {
		return self
			.replacingOccurrences(of: "_", with: " ")
			.capitalized
	}
}
