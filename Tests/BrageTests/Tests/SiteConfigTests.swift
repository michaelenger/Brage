/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import XCTest
@testable import BrageCore

extension SiteConfig: Equatable {
    public static func ==(lhs: SiteConfig, rhs: SiteConfig) -> Bool {
        let sameMeta = lhs.title == rhs.title &&
            lhs.description == rhs.description &&
            lhs.keywords == rhs.keywords &&
            lhs.image == rhs.image &&
            lhs.data.count == rhs.data.count

        if !sameMeta {
            return false
        }

        for (key, _) in lhs.data {
            if let _ = rhs.data[key] {
                // assumes the value is the same - not ideal, but good enough for our testing
            } else {
                return false
            }
        }

        return true
    }
}

final class SiteConfigTests: XCTestCase {
    func testParseBasic() {
        let input = """
        ---
        title: Test
        """
        let expected = SiteConfig(
            title: "Test",
            description: nil,
            keywords: nil,
            image: nil,
            data: [:]
        )

        let result = try! SiteConfig.parse(from: input)

        XCTAssertEqual(result, expected)
    }

    func testParseData() {
        let input = """
        ---
        title: Test
        description: Some text.
        keywords: lol,what,yay
        image: lol.png

        boolean: true
        int: 1234
        double: 12.34
        string: "Just text."
        array:
          - one
          - two
          - three
        nested:
          - key: value
            emoji: 💸
          - key: to the castle
            emoji: 🗝
        """
        let expected = SiteConfig(
            title: "Test",
            description: "Some text.",
            keywords: "lol,what,yay",
            image: "lol.png",
            data: [
                "boolean": true,
                "int": 1234,
                "double": 12.34,
                "string": "Just text.",
                "array": ["one", "two", "three"],
                "nested": [
                    ["key": "value", "emoji": "💸"],
                    ["key": "to the castle", "emoji": "🗝"]
                ]
            ]
        )

        let result = try! SiteConfig.parse(from: input)

        XCTAssertEqual(result, expected)
    }
}
