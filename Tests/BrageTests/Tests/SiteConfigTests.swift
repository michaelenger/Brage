/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import XCTest
@testable import BrageCore

final class SiteConfigTests: XCTestCase {
    func testParseBasic() {
        let input = """
        ---
        title: Test
        """
        let result = try! SiteConfig.parse(from: input)
        
        XCTAssertEqual(result.title, "Test")
        XCTAssertEqual(result.description, nil)
        XCTAssertEqual(result.image, nil)
        XCTAssertEqual(result.data.count, 0)
    }
    
    func testParseData() {
        let input = """
        ---
        title: Test
        description: Some text.
        image: lol.png
        data:
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
        let result = try! SiteConfig.parse(from: input)

        XCTAssertEqual(result.title, "Test")
        XCTAssertEqual(result.description, "Some text.")
        XCTAssertEqual(result.image, "lol.png")
        XCTAssertEqual(result.data.count, 6)
        XCTAssertEqual(result.data["boolean"] as! Bool, true)
        XCTAssertEqual(result.data["int"] as! Int, 1234)
        XCTAssertEqual(result.data["double"] as! Double, 12.34)
        XCTAssertEqual(result.data["string"] as! String, "Just text.")
        XCTAssertEqual(result.data["array"] as! [String], ["one", "two", "three"])
        XCTAssertEqual(result.data["nested"] as! [[String: String]], [
            ["key": "value", "emoji": "💸"],
            ["key": "to the castle", "emoji": "🗝"]
        ])
    }
}
