/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Yaml

public struct SiteConfig: Codable, Equatable {
	public let title: String
	public let description: String?
    public let image: String?

    /// Parse a YAML string into a site config.
    ///
    /// - Parameter from: Text to parse from.
    /// - Returns: Site configuration.
    public static func parse(from text: String) throws -> SiteConfig {
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
}

public enum SiteConfigParseError: Error {
	case missingTitle
}
