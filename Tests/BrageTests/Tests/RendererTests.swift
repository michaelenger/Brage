/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Files
import XCTest
@testable import BrageCore

final class RendererTests: XCTestCase {
    private var sourceDirectory: Folder!

    override func setUp() {
        super.setUp()

        // Create temporary directory
        sourceDirectory = try! Folder.temporary.createSubfolderIfNeeded(withName: ".rendererTests")
        try! sourceDirectory.empty()

        // Fill it with some example data
        try! sourceDirectory.createFile(
            named: "site.yaml",
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
    }

    override func tearDown() {
        // Remove the temporary directory
        try? sourceDirectory.delete()
        super.tearDown()
    }

    func testBuildMissingSiteConfig() throws {
        let siteConfigFile = try sourceDirectory.file(named: "site.yaml")
        try siteConfigFile.delete()
        
        do {
            _ = try Renderer(source: sourceDirectory)
        } catch let e as RendererError {
            XCTAssertEqual(e, RendererError.missingSiteConfig)
        }
    }

    func testBuildMissingLayoutTemplate() throws {
        let layoutFile = try sourceDirectory.file(named: "layout.html")
        try layoutFile.delete()

        do {
            _ = try Renderer(source: sourceDirectory)
        } catch let e as RendererError {
            XCTAssertEqual(e, RendererError.missingLayoutTemplate)
        }
    }

    func testRenderImportedTemplate() throws {
        let templateFile = try sourceDirectory.createFile(
            named: "index.html",
            contents: Data("So Above {% include \"other.html\" %} So Below".utf8))

        let templateDirectory = try sourceDirectory.createSubfolderIfNeeded(withName: "templates")
        try templateDirectory.createFile(
            named: "other.html",
            contents: Data("--".utf8))

        let renderer = try Renderer(source: sourceDirectory)
        let result = try renderer.render(file: templateFile)
        let expected = "<title>Test Site</title><body>So Above -- So Below</body>"

        XCTAssertEqual(result, expected)
    }

    func testRenderMarkdownTemplate() throws {
        let templateFile = try sourceDirectory.createFile(
            named: "testpage.markdown",
            contents: Data("THIS IS **TEST**".utf8))

        let renderer = try Renderer(source: sourceDirectory)
        let result = try renderer.render(file: templateFile)
        let expected = "<title>Test Site</title><body><p>THIS IS <strong>TEST</strong></p></body>"

        XCTAssertEqual(result, expected)
    }

    func testRenderStencilTemplate() throws {
        let templateFile = try sourceDirectory.createFile(
            named: "testpage.html",
            contents: Data("THIS IS {{page.title}}".utf8))

        let renderer = try Renderer(source: sourceDirectory)
        let result = try renderer.render(file: templateFile)
        let expected = "<title>Test Site</title><body>THIS IS Testpage</body>"

        XCTAssertEqual(result, expected)
    }

    func testRenderUnknownTemplate() throws {
        let templateFile = try sourceDirectory.createFile(
            named: "testpage.lol",
            contents: Data("THIS IS {{page.title}}".utf8))
        
        let renderer = try Renderer(source: sourceDirectory)

        do {
            _ = try renderer.render(file: templateFile)
        } catch let e as RendererError {
            XCTAssertEqual(e, RendererError.unrecognizedTemplate("testpage.lol"))
        }
    }

    func testStencilVariables() throws {
        let templateFile = try sourceDirectory.createFile(
            named: "testpage.html",
            contents: Data("""

            {{site.title}}
            {{site.description}}
            {{site.image}}
            {{site.root}}
            {{site.assets}}
            {{page.title}}
            {{page.uri}}
            {{data.text}}

            """.utf8))

        let renderer = try Renderer(source: sourceDirectory)
        let result = try renderer.render(file: templateFile)
        let expected = """
        <title>Test Site</title><body>
        Test Site
        This is just a test.
        ./assets/lol.png
        ./
        ./assets/
        Testpage
        /
        A friendly little 🌲
        </body>
        """

        XCTAssertEqual(result, expected)
    }
    
    func testStencilVariablesWithUri() throws {
        let templateFile = try sourceDirectory.createFile(
            named: "testpage.html",
            contents: Data("""

            {{site.title}}
            {{site.description}}
            {{site.image}}
            {{site.root}}
            {{site.assets}}
            {{page.title}}
            {{page.uri}}
            {{data.text}}

            """.utf8))

        let renderer = try Renderer(source: sourceDirectory)
        let result = try renderer.render(file: templateFile, uri: "/some/test")
        let expected = """
        <title>Test Site</title><body>
        Test Site
        This is just a test.
        ../../assets/lol.png
        ../../
        ../../assets/
        Testpage
        /some/test
        A friendly little 🌲
        </body>
        """

        XCTAssertEqual(result, expected)
    }
}
