/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Files
import Stencil
import XCTest
@testable import BrageCore

final class MarkdownLoaderTests: XCTestCase {
    private var testEnvironment: Environment!
    private var sourceDirectory: Folder!
    
    override func setUp() {
        super.setUp()
        
        testEnvironment = Environment()

        sourceDirectory = try! Folder.temporary.createSubfolderIfNeeded(withName: ".markdownLoaderTests")
        try! sourceDirectory.empty()
    }

    override func tearDown() {
        try? sourceDirectory.delete()
        super.tearDown()
    }
    
    func testLoadTemplateMarkdown() throws {
        let templateFile = try! sourceDirectory.createFile(named: "test.md")
        try! templateFile.write("This is a **test**.")
        let loader = MarkdownLoader(templateDirectory: sourceDirectory)
        
        let template = try loader.loadTemplate(name: "test.md", environment: testEnvironment)
        let result = try template.render()
        
        XCTAssertEqual(result, "<p>This is a <strong>test</strong>.</p>")
    }

    func testLoadTemplateMarkdownAlternative() throws {
        let templateFile = try! sourceDirectory.createFile(named: "test.markdown")
        try! templateFile.write("This is a ~~dumb~~ test.")
        let loader = MarkdownLoader(templateDirectory: sourceDirectory)
        
        let template = try loader.loadTemplate(name: "test.markdown", environment: testEnvironment)
        let result = try template.render()
        
        XCTAssertEqual(result, "<p>This is a <s>dumb</s> test.</p>")
    }
    
    func testLoadTemplateRegular() throws {
        let templateFile = try! sourceDirectory.createFile(named: "test.html")
        try! templateFile.write("This is a test <a href=>link</a>.")
        let loader = MarkdownLoader(templateDirectory: sourceDirectory)
        
        let template = try loader.loadTemplate(name: "test.html", environment: testEnvironment)
        let result = try template.render()
        
        XCTAssertEqual(result, "This is a test <a href=>link</a>.")
    }
    
    func testLoadTemplateSubdirectory() throws {
        let subdir = try! sourceDirectory.createSubfolder(at: "one/two/three")
        let templateFile = try! subdir.createFile(named: "test.md")
        try! templateFile.write("This is _another_ test.")
        let loader = MarkdownLoader(templateDirectory: sourceDirectory)
        
        let template = try loader.loadTemplate(name: "one/two/three/test.md", environment: testEnvironment)
        let result = try template.render()
        
        XCTAssertEqual(result, "<p>This is <em>another</em> test.</p>")
    }
    
    func testLoadTemplateMissingTemplate() throws {
        let loader = MarkdownLoader(templateDirectory: sourceDirectory)
        
        do {
            _ = try loader.loadTemplate(name: "test.md", environment: testEnvironment)
        } catch let e as TemplateDoesNotExist {
            XCTAssertEqual(e.description, "Template named `test.md` does not exist in loader BrageCore.MarkdownLoader")
       }
    }
}
