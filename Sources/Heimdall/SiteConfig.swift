/**
 *  Heimdall
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Yaml

public struct SiteConfig {
	public let title: String
	public let description: String?
	public let image: String?
}

public func parseConfig(from text: String) throws -> SiteConfig {
	let config = try Yaml.load(text)

	guard config["title"].string != nil else {
		throw SiteConfigParseError.missingTitle
	}

	return SiteConfig(
		title: config["title"].string!,
		description: config["description"].string,
		image: config["image"].string
	)
}

public enum SiteConfigParseError: Error {
	case missingTitle
}
