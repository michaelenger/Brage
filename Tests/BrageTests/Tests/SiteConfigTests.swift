//
//  SiteConfigTests.swift
//  
//
//  Created by Michael Enger on 03/02/2021.
//

import XCTest
@testable import BrageCore

final class SiteConfigTests: XCTestCase {
    func testParseBasic() {
        let input = """
        ---
        title: Test
        """
        let result = try! SiteConfig.parse(from: input)
        let expected = SiteConfig(title: "Test", description: nil, image: nil)
        
        XCTAssertEqual(result, expected)
    }
    
    func testParseFull() {
        let input = """
        ---
        title: Test
        description: Some text.
        image: lol.png
        """
        let result = try! SiteConfig.parse(from: input)
        let expected = SiteConfig(title: "Test", description: "Some text.", image: "lol.png")
        
        XCTAssertEqual(result, expected)
    }
}
