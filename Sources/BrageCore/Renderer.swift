/**
*  Brage
*  Copyright (c) Michael Enger 2021
*  MIT license, see LICENSE file for details
*/

import Files
import Ink
import Stencil

/// Renderer which can transform a template file into HTML content.
public struct Renderer {
    private let layoutTemplate: String
    private let siteConfig: SiteConfig
    private let sourceDirectory: Folder
    private let stencilEnvironment: Environment
    
    /// Initialize the renderer with the specified source site directory.
    ///
    /// - Parameter source: Site directory to base the renderer on.
    public init(source: Folder) throws {
        self.sourceDirectory = source
        
        // Load the site config
        let configString: String
        if sourceDirectory.containsFile(named: "site.yaml") {
            configString = try sourceDirectory.file(named: "site.yaml").readAsString()
        } else if sourceDirectory.containsFile(named: "site.yml") {
            configString = try sourceDirectory.file(named: "site.yml").readAsString()
        } else {
            throw RendererError.missingSiteConfig
        }
        
        self.siteConfig = try SiteConfig.parse(from: configString)
        
        // Read the layout template
        do {
            self.layoutTemplate = try sourceDirectory.file(named: "layout.html").readAsString()
        } catch is FilesError<LocationErrorReason> {
            throw RendererError.missingLayoutTemplate
        }
        
        // Construct render environment
        do {
            let templateDirectory = try sourceDirectory.subfolder(named:"templates")
            let loader = MarkdownLoader(templateDirectory: templateDirectory)
            stencilEnvironment = Environment(loader: loader)
        } catch is FilesError<LocationErrorReason> {
            // No templates for you
            stencilEnvironment = Environment()
        }
    }
    
    /// Render a template file.
    ///
    /// - Parameter file: Template file to render.
    /// - Parameter path: URI the page will be renderered at.
    /// - Returns: HTML content.
    public func render(file: File, uri: String = "/") throws -> String {
        // Build data object
        let rootPath = uri != "/"
            ? String(repeating: "../", count: uri.count(of: Character("/")))
            : "./"

        let pageData = TemplateData(
            site: TemplateSiteData(
                title: siteConfig.title,
                description: siteConfig.description,
                image: siteConfig.image,
                root: rootPath
            ),
            page: TemplatePageData(
                title: file.nameExcludingExtension.titleified,
                uri: uri,
                content: nil
            ),
            data: siteConfig.data
        )
        
        // Render file
        let pageContent: String

        switch file.extension?.lowercased() {
        case "markdown", "md":
            pageContent = try renderMarkdownTemplate(from: file)
        case "html":
            let fileContents = try file.readAsString()
            pageContent = try renderStencilTemplate(
                environment: stencilEnvironment,
                template: fileContents,
                data: pageData
            )
        default:
            throw RendererError.unrecognizedTemplate(file.name)
        }
        
        let layoutData = TemplateData(
            site: pageData.site,
            page: TemplatePageData(
                title: pageData.page.title,
                uri: uri,
                content: pageContent
            ),
            data: pageData.data
        )
        return try renderStencilTemplate(
            environment: stencilEnvironment,
            template: layoutTemplate,
            data: layoutData
        )
    }
    
    /// Render a markdown template from a specified file.
    ///
    /// - Parameter from: File to read and render markdown from.
    /// - Returns: Rendered HTML content.
    private func renderMarkdownTemplate(from file: File) throws -> String {
        let fileContents = try file.readAsString()
        let parser = MarkdownParser()
        
        return parser.html(from: fileContents)
    }

    /// Render a Stencil template from a specified file.
    ///
    /// - Parameter environment: Render environment to use.
    /// - Parameter file: File to read and render from.
    /// - Parameter data: Data to send to the template.
    /// - Returns: Rendered HTML content.
    private func renderStencilTemplate(environment: Environment, template: String, data: TemplateData) throws -> String {
        return try environment.renderTemplate(string: template, context: [
            "site": [
                "title": data.site.title,
                "description": data.site.description as Any,
                "image": data.site.image as Any,
                "root": data.site.root,
            ],
            "page": [
                "title": data.page.title,
                "uri": data.page.uri,
                "content": data.page.content as Any,
            ],
            "data": data.data
        ])
    }
}

/// File extensions which are supported by the renderer.
public enum RendererFileExtensions: String, CaseIterable {
    case html = "html"
    case markdown = "markdown"
    case markdownShort = "md"
}

public enum RendererError: Error, Equatable {
    case missingLayoutTemplate
    case missingPagesDirectory
    case missingSiteConfig
    case unrecognizedTemplate(String)
}

public struct TemplateSiteData {
    public let title: String
    public let description: String?
    public let image: String?
    public let root: String
}

public struct TemplatePageData {
    public let title: String
    public let uri: String
    public let content: String?
}

public struct TemplateData {
    public let site: TemplateSiteData
    public let page: TemplatePageData
    public let data: [String: Any]
}
