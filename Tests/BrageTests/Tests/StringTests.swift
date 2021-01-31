/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import XCTest
@testable import BrageCore

final class StringTests: XCTestCase {
	func testCount() {
		let c = Character("f")

		XCTAssertEqual("".count(of: c), 0)
		XCTAssertEqual("fail".count(of: c), 1)
		XCTAssertEqual("ffffffffffffff".count(of: c), 14)
		XCTAssertEqual("for the fun of failing".count(of: c), 4)
	}

	func testTitleified() {
		XCTAssertEqual("".titleified, "")
		XCTAssertEqual("test".titleified, "Test")
		XCTAssertEqual("another_test".titleified, "Another Test")
		XCTAssertEqual("what tHE_fudge".titleified, "What The Fudge")
	}
}
