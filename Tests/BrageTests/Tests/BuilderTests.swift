/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Files
import XCTest
@testable import BrageCore

final class BuilderTests: XCTestCase {
	private var siteDirectory: Folder!
    private var builder: Builder!

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
        
        self.builder = Builder()
	}

	override func tearDown() {
		// Remove the temporary directory
		try? siteDirectory.delete()
		super.tearDown()
	}

	func testBuildMissingSiteDirectory() throws {
		do {
            try builder.build(fromSource: "\(Folder.temporary)doesnotexist")
		} catch let e as BuilderError {
			XCTAssertEqual(e, BuilderError.missingSiteDirectory)
		}
	}

	func testBuildMissingSiteConfig() throws {
		try! siteDirectory.empty()
        
		do {
            try builder.build(fromSource: siteDirectory.path)
		} catch let e as BuilderError {
			XCTAssertEqual(e, BuilderError.missingSiteConfig)
		}
	}

	func testBuildMissingLayoutTemplate() throws {
		let layoutFile = try! siteDirectory.file(named: "layout.mustache")
		try! layoutFile.delete()

		do {
            try builder.build(fromSource: siteDirectory.path)
		} catch let e as BuilderError {
			XCTAssertEqual(e, BuilderError.missingLayoutTemplate)
		}
	}

	func testRenderMustacheTemplate() throws {
		let pagesDirectory = try siteDirectory.createSubfolderIfNeeded(withName: "pages")
		let pageFile = try! pagesDirectory.createFile(
			named: "testpage.mustache",
			contents: Data("THIS IS {{site.title}}".utf8))
		let templateData = TemplateData(
			site: TemplateSiteData(
				title: "Test Page",
				description: nil,
				root: "./",
				assets: "./assets/"
			),
			page: TemplatePageData(
				title: "Index",
				path: "./",
				content: nil
			)
		)

		let result = try builder.renderMustacheTemplate(from: pageFile, data: templateData)
		XCTAssertEqual(result, "THIS IS Test Page")
	}
}
