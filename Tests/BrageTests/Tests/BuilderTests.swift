/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Files
import XCTest
@testable import BrageCore

final class BuilderTests: XCTestCase {
	private var sourceDirectory: Folder!
    private var targetDirectory: Folder!
    private var builder: Builder!

	override func setUp() {
		super.setUp()

		// Create temporary directory
		sourceDirectory = try! Folder.temporary.createSubfolderIfNeeded(withName: ".builderTests")
		try! sourceDirectory.empty()
        targetDirectory = try! sourceDirectory.createSubfolderIfNeeded(withName: "build")

		// Fill it with some example data
		try! sourceDirectory.createFile(
			named: "site.yml",
			contents: Data("---\ntitle: Test Site\n".utf8))
		try! sourceDirectory.createFile(
            named: "layout.html",
			contents: Data("<title>{{site.title}}</title><body>{{page.content}}</body>".utf8))
        
        self.builder = Builder()
	}

	override func tearDown() {
		// Remove the temporary directory
		try? sourceDirectory.delete()
		super.tearDown()
	}

	func testBuildMissingSiteConfig() throws {
		try! sourceDirectory.empty()
        
		do {
            try builder.build(source: sourceDirectory, target: targetDirectory)
		} catch let e as BuilderError {
			XCTAssertEqual(e, BuilderError.missingSiteConfig)
		}
	}

	func testBuildMissingLayoutTemplate() throws {
        let layoutFile = try! sourceDirectory.file(named: "layout.html")
		try! layoutFile.delete()

		do {
            try builder.build(source: sourceDirectory, target: targetDirectory)
		} catch let e as BuilderError {
			XCTAssertEqual(e, BuilderError.missingLayoutTemplate)
		}
	}
    
    func testRenderImportedTemplate() throws {
        let pagesDirectory = try sourceDirectory.createSubfolderIfNeeded(withName: "pages")
        try! pagesDirectory.createFile(
            named: "index.html",
            contents: Data("So Above {% include \"other.html\" %} So Below".utf8))
    
        let templateDirectory = try sourceDirectory.createSubfolderIfNeeded(withName: "templates")
        try! templateDirectory.createFile(
            named: "other.html",
            contents: Data("--".utf8))

        try builder.build(source: sourceDirectory, target: targetDirectory)
        
        let result = try sourceDirectory.file(at: "build/index.html").readAsString()
        let expected = "<title>Test Site</title><body>So Above -- So Below</body>"
        
        XCTAssertEqual(result, expected)
    }
    
    func testRenderMarkdownTemplate() throws {
        let pagesDirectory = try sourceDirectory.createSubfolderIfNeeded(withName: "pages")
        try! pagesDirectory.createFile(
            named: "testpage.markdown",
            contents: Data("THIS IS **TEST**".utf8))

        try builder.build(source: sourceDirectory, target: targetDirectory)
        
        let result = try sourceDirectory.file(at: "build/testpage/index.html").readAsString()
        let expected = "<title>Test Site</title><body><p>THIS IS <strong>TEST</strong></p></body>"
        
        XCTAssertEqual(result, expected)
    }

	func testRenderStencilTemplate() throws {
        let pagesDirectory = try sourceDirectory.createSubfolderIfNeeded(withName: "pages")
        try! pagesDirectory.createFile(
            named: "testpage.html",
            contents: Data("THIS IS {{page.title}}".utf8))

        try builder.build(source: sourceDirectory, target: targetDirectory)
        
        let result = try sourceDirectory.file(at: "build/testpage/index.html").readAsString()
        let expected = "<title>Test Site</title><body>THIS IS Testpage</body>"
        
        XCTAssertEqual(result, expected)
    }
    
    func testRenderUnknownTemplate() throws {
        let pagesDirectory = try sourceDirectory.createSubfolderIfNeeded(withName: "pages")
        try! pagesDirectory.createFile(
            named: "testpage.lol",
            contents: Data("THIS IS {{page.title}}".utf8))

        do {
            try builder.build(source: sourceDirectory, target: targetDirectory)
        } catch let e as BuilderError {
            XCTAssertEqual(e, BuilderError.unrecognizedTemplate("testpage.lol"))
        }
    }
}
