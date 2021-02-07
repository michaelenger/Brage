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
    private var pagesDirectory: Folder!
    private var targetDirectory: Folder!
    private var renderer: Renderer!
    private var builder: Builder!

	override func setUp() {
		super.setUp()

		// Create temporary directory
		sourceDirectory = try! Folder.temporary.createSubfolderIfNeeded(withName: ".builderTests")
		try! sourceDirectory.empty()
        pagesDirectory = try! sourceDirectory.createSubfolderIfNeeded(at: "pages")
        targetDirectory = try! sourceDirectory.createSubfolderIfNeeded(withName: "build")

		// Fill it with some example data
		try! sourceDirectory.createFile(
			named: "site.yml",
			contents: Data("""
            ---
            title: Test Site
            description: This is just a test.
            image: lol.png
            data:
              text: A friendly little 🌲
            """.utf8))
		try! sourceDirectory.createFile(
            named: "layout.html",
			contents: Data("<title>{{site.title}}</title><body>{{page.content}}</body>".utf8))

        self.renderer = try! Renderer(source: sourceDirectory)
        self.builder = Builder(source: sourceDirectory, renderer: self.renderer)
	}

	override func tearDown() {
		// Remove the temporary directory
		try? sourceDirectory.delete()
		super.tearDown()
	}

	func testBuildIndex() throws {
        try pagesDirectory.createFile(named: "index.html").write("I am {{page.title}} at {{page.path}}.")
        try builder.build(target: targetDirectory)
        
        let contents = try targetDirectory.file(at: "index.html").readAsString()
        XCTAssertEqual(contents, """
        <title>Test Site</title><body>I am Index at /.</body>
        """)
	}
    
    func testBuildSubDirectory() throws {
        let subDirectory = try pagesDirectory.createSubfolderIfNeeded(at: "sub")
        try subDirectory.createFile(named: "test.html").write("I am {{page.title}} at {{page.path}}.")
        let anotherDirectory = try pagesDirectory.createSubfolderIfNeeded(at: "another")
        try anotherDirectory.createFile(named: "page.html").write("I am {{page.title}} at {{page.path}}.")
        try builder.build(target: targetDirectory)
        
        var contents = try targetDirectory.file(at: "sub/test/index.html").readAsString()
        XCTAssertEqual(contents, """
        <title>Test Site</title><body>I am Test at /sub/test.</body>
        """)
        contents = try targetDirectory.file(at: "another/page/index.html").readAsString()
        XCTAssertEqual(contents, """
        <title>Test Site</title><body>I am Page at /another/page.</body>
        """)
    }
    
    func testBuildMissingPages() throws {
        do {
            try builder.build(target: targetDirectory)
        } catch let e as BuilderError {
            XCTAssertEqual(e, BuilderError.missingPagesDirectory)
        }
    }
    
    func testBuildAssets() throws {
        let assetsDirectory = try sourceDirectory.createSubfolderIfNeeded(at: "assets")
        try assetsDirectory.createFile(named: "styles.css").write("body { background: '#f09'; }")
        try assetsDirectory.createFile(named: "js/scripts.js").write("console.log('It works!');")
        try builder.build(target: targetDirectory)
        
        var contents = try targetDirectory.file(at: "assets/styles.css").readAsString()
        XCTAssertEqual(contents, "body { background: '#f09'; }")
        contents = try targetDirectory.file(at: "assets/js/scripts.js").readAsString()
        XCTAssertEqual(contents, "console.log('It works!');")
    }
}
