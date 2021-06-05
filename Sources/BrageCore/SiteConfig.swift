/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Yaml

public struct SiteConfig {
	public let title: String
	public let description: String?
    public let keywords: String?
    public let image: String?
    public let data: [String: Any]

    /// Parse a YAML string into a site config.
    ///
    /// - Parameter from: Text to parse from.
    /// - Returns: Site configuration.
    public static func parse(from text: String) throws -> SiteConfig {
        let config = try Yaml.load(text)

        guard config["title"].string != nil else {
            throw SiteConfigParseError.missingTitle
        }
        
        var data: [String: Any] = [:]
        for (key, value) in config.dictionary! {
            let key = key.string!
            switch key {
            case "title", "description", "keywords", "image":
                break // just skip it
            default:
                data[key] = try convert(value)
            }
        }

        return SiteConfig(
            title: config["title"].string!,
            description: config["description"].string,
            keywords: config["keywords"].string,
            image: config["image"].string,
            data: data
        )
    }
}

/// Convert a YAML value to a regular object.
///
/// - Parameter value: YAML value to convert.
/// - Returns: The converted value (nil if unable to convert).
private func convert(_ value: Yaml) throws -> Any {
    if value.array != nil {
        return try value.array!.map { (item) -> Any in
            return try convert(item)
        }
    }
    if value.dictionary != nil {
        var dict: [String: Any] = [:]
        for (k, v) in value.dictionary! {
            dict[k.string!] = try convert(v)
        }
        return dict
    }
    if value.bool != nil {
        return value.bool!
    }
    if value.int != nil {
        return value.int!
    }
    if value.double != nil {
        return value.double!
    }
    if value.string != nil {
        return value.string!
    }

    throw SiteConfigParseError.conversionError("Unable to convert \(value)")
}

public enum SiteConfigParseError: Error {
	case missingTitle
    case conversionError(String)
}
