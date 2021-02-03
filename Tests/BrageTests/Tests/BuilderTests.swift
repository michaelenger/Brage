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
			contents: Data("---\ntitle: Test Site\n".utf8))
		try! siteDirectory.createFile(
			named: "layout.stencil",
			contents: Data("<title>{{site.title}}</title><body>{{page.content}}</body>".utf8))
        
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
		let layoutFile = try! siteDirectory.file(named: "layout.stencil")
		try! layoutFile.delete()

		do {
            try builder.build(fromSource: siteDirectory.path)
		} catch let e as BuilderError {
			XCTAssertEqual(e, BuilderError.missingLayoutTemplate)
		}
	}
    
    func testRenderMarkdownTemplate() throws {
        let pagesDirectory = try siteDirectory.createSubfolderIfNeeded(withName: "pages")
        try! pagesDirectory.createFile(
            named: "testpage.markdown",
            contents: Data("THIS IS **TEST**".utf8))

        try builder.build(fromSource: siteDirectory.path)
        
        let result = try siteDirectory.file(at: "build/testpage/index.html").readAsString()
        let expected = "<title>Test Site</title><body><p>THIS IS <strong>TEST</strong></p></body>"
        
        XCTAssertEqual(result, expected)
    }

	func testRenderStencilTemplate() throws {
		let pagesDirectory = try siteDirectory.createSubfolderIfNeeded(withName: "pages")
		try! pagesDirectory.createFile(
			named: "testpage.stencil",
			contents: Data("THIS IS {{page.title}}".utf8))

        try builder.build(fromSource: siteDirectory.path)
        
        let result = try siteDirectory.file(at: "build/testpage/index.html").readAsString()
        let expected = "<title>Test Site</title><body>THIS IS Testpage</body>"
        
        XCTAssertEqual(result, expected)
	}
    
    func testRenderHTMLTemplate() throws {
        let layoutFile = try! siteDirectory.file(named: "layout.stencil")
        try! layoutFile.rename(to: "layout.html", keepExtension: false)
        
        let pagesDirectory = try siteDirectory.createSubfolderIfNeeded(withName: "pages")
        try! pagesDirectory.createFile(
            named: "testpage.html",
            contents: Data("THIS IS {{page.title}}".utf8))

        try builder.build(fromSource: siteDirectory.path)
        
        let result = try siteDirectory.file(at: "build/testpage/index.html").readAsString()
        let expected = "<title>Test Site</title><body>THIS IS Testpage</body>"
        
        XCTAssertEqual(result, expected)
    }
    
    func testRenderUnknownTemplate() throws {
        let pagesDirectory = try siteDirectory.createSubfolderIfNeeded(withName: "pages")
        try! pagesDirectory.createFile(
            named: "testpage.lol",
            contents: Data("THIS IS {{page.title}}".utf8))

        do {
            try builder.build(fromSource: siteDirectory.path)
        } catch let e as BuilderError {
            XCTAssertEqual(e, BuilderError.unrecognizedTemplate("testpage.lol"))
        }
    }
}
