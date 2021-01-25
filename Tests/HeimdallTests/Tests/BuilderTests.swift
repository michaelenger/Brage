/**
 *  Heimdall
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Files
import XCTest
@testable import HeimdallCore

final class BuilderTests: XCTestCase {
	private var siteDirectory: Folder!

	override func setUp() {
		super.setUp()

		// Create temporary directory
		siteDirectory = try! Folder.temporary.createSubfolderIfNeeded(withName: ".builderTests")
		try! siteDirectory.empty()

		// Fill it with some example data
		try! siteDirectory.createFile(
			named: "site.yml",
			contents: Data("---\ntitle: Test Page\n".utf8))
		try! siteDirectory.createFile(
			named: "layout.mustache",
			contents: Data("<title>{{site.title}}</title><body>{{{page.content}}}</body>".utf8))
	}

	override func tearDown() {
		// Remove the temporary directory
		try? siteDirectory.delete()
		super.tearDown()
	}

	func testInit() throws {
		_ = try Builder(basedOn: siteDirectory.path)
	}

	func testInitMissingSiteDirectory() throws {
		do {
			_ = try Builder(basedOn: "\(Folder.temporary)doesnotexist")
		} catch let e as BuilderError {
			XCTAssertEqual(e, BuilderError.missingSiteDirectory)
		}
	}

	func testInitMissingSiteConfig() throws {
		try! siteDirectory.empty()

		do {
			_ = try Builder(basedOn: siteDirectory.path)
		} catch let e as BuilderError {
			XCTAssertEqual(e, BuilderError.missingSiteConfig)
		}
	}

	func testInitMissingLayoutTemplate() throws {
		let layoutFile = try! siteDirectory.file(named: "layout.mustache")
		try! layoutFile.delete()

		do {
			_ = try Builder(basedOn: siteDirectory.path)
		} catch let e as BuilderError {
			XCTAssertEqual(e, BuilderError.missingLayoutTemplate)
		}
	}

	func testRenderTemplateMustache() throws {
		let builder = try Builder(basedOn: siteDirectory.path)

		let pagesDirectory = try siteDirectory.createSubfolderIfNeeded(withName: "pages")
		let pageFile = try! pagesDirectory.createFile(
			named: "testpage.mustache",
			contents: Data("THIS IS CONTENT".utf8))

		let result = try builder.renderTemplate(from: pageFile)
		XCTAssertEqual(result, "<title>Test Page</title><body>THIS IS CONTENT</body>")
	}

	static var allTests = [
		("testRenderTemplate", testRenderTemplateMustache),
	]
}
