/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Files
import Foundation
import Ink
import PathKit
import Stencil

public struct Builder {
    /// Build a site based on a site directory.
    ///
    /// - Parameter source: Site directory of the site to build.
    /// - Parameter target: Destination for the rendered HTML files.
    public func build(source sourceDirectory: Folder, target targetDirectory: Folder) throws {
        // Load config and layout
        let config = try loadConfig(from: sourceDirectory)
        let layoutTemplate: String
        do {
            layoutTemplate = try sourceDirectory.file(named: "layout.html").readAsString()
        } catch is FilesError<LocationErrorReason> {
            throw BuilderError.missingLayoutTemplate
        }

		// Get the pages directory
		let pagesDirectory: Folder
		do {
			pagesDirectory = try sourceDirectory.subfolder(named: "pages")
		} catch is FilesError<LocationErrorReason> {
			throw BuilderError.missingPagesDirectory
		}

		// Copy assets
		do {
			let assetsDirectory = try sourceDirectory.subfolder(named: "assets")
            if targetDirectory.containsSubfolder(named: "assets") {
                try targetDirectory.subfolder(named: "assets").delete()
            }
			try assetsDirectory.copy(to: targetDirectory)
		} catch is FilesError<LocationErrorReason> {
			// No assets to copy
		}
        
        // Construct render environment
        let environment: Environment
        do {
            let templateDirectory = try sourceDirectory.subfolder(named:"templates")
            let loader = MarkdownLoader(templateDirectory: templateDirectory)
            environment = Environment(loader: loader)
        } catch is FilesError<LocationErrorReason> {
            // No templates for you
            environment = Environment()
        }

		// Render templates
		let files = pagesDirectory.files.recursive
		for file in files {
			// Determine where to render
			var currentDirectory = targetDirectory
			if file.nameExcludingExtension != "index" {
				let targetPath = file.path(relativeTo: pagesDirectory)
					.split(separator: ".")
					.dropLast()
					.joined()
				currentDirectory = try targetDirectory.createSubfolder(at: targetPath)
			}

			// Build data object
			let uri = "/\(currentDirectory.path(relativeTo: targetDirectory))"
			let rootPath = uri != "/"
				? String(repeating: "../", count: uri.count(of: Character("/")))
				: "./"

			let pageData = TemplateData(
				site: TemplateSiteData(
					title: config.title,
					description: config.description,
                    image: config.image != nil ? "\(rootPath)assets/\(config.image!)" : nil,
					root: rootPath,
					assets: "\(rootPath)assets/"
				),
				page: TemplatePageData(
					title: uri == "/" ? "Index" : currentDirectory.name.titleified,
					path: uri,
					content: nil
				),
                data: config.data
			)

			// Render template
			let targetFile = try currentDirectory.createFile(named: "index.html")
            let pageContent: String
            
            switch file.extension?.lowercased() {
            case "markdown", "md":
                pageContent = try renderMarkdownTemplate(from: file)
            case "html":
                let fileContents = try file.readAsString()
                pageContent = try renderStencilTemplate(environment: environment, template: fileContents, data: pageData)
            default:
                throw BuilderError.unrecognizedTemplate(file.name)
            }
            
            let layoutData = TemplateData(
                site: pageData.site,
                page: TemplatePageData(
                    title: pageData.page.title,
                    path: uri,
                    content: pageContent
                ),
                data: pageData.data
            )
            let content = try renderStencilTemplate(environment: environment, template: layoutTemplate, data: layoutData)

			try targetFile.write(content)
		}
	}
    
    /// Load the site config from the specified site directory.
    ///
    /// - Parameter from: Site directory to load the config from.
    /// - Returns: The site config.
    private func loadConfig(from directory: Folder) throws -> SiteConfig {
        let configString: String
        if directory.containsFile(named: "site.yaml") {
            configString = try directory.file(named: "site.yaml").readAsString()
        } else if directory.containsFile(named: "site.yml") {
            configString = try directory.file(named: "site.yml").readAsString()
        } else {
            throw BuilderError.missingSiteConfig
        }
        
        return try SiteConfig.parse(from: configString)
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
                "assets": data.site.assets,
            ],
            "page": [
                "title": data.page.title,
                "path": data.page.path,
                "content": data.page.content as Any,
            ],
            "data": data.data
		])
	}
}

public enum BuilderError: Error, Equatable {
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
	public let assets: String
}

public struct TemplatePageData {
	public let title: String
	public let path: String
	public let content: String?
}

public struct TemplateData {
	public let site: TemplateSiteData
	public let page: TemplatePageData
    public let data: [String: Any]
}
