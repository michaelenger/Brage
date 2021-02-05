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
    /// - Parameter fromSource: Path to the directory of the site to build.
    public func build(source sourceDirectory: Folder) throws {
        // Load config and layout
        let config = try loadConfig(from: sourceDirectory)
        let layoutTemplate: String
        do {
            layoutTemplate = try sourceDirectory.file(at: "layout.html").readAsString()
        } catch is FilesError<LocationErrorReason> {
            throw BuilderError.missingLayoutTemplate
        }

		// Get the pages directory
		let pagesDirectory: Folder
		do {
			pagesDirectory = try sourceDirectory.subfolder(at: "pages")
		} catch is FilesError<LocationErrorReason> {
			throw BuilderError.missingPagesDirectory
		}

		// Clear and create build directory
		do {
			let buildDirectory = try sourceDirectory.subfolder(at: "build")
			try buildDirectory.delete()
		} catch is FilesError<LocationErrorReason> {
			// this is fine 🔥
		}
		let buildDirectory = try sourceDirectory.createSubfolder(at: "build")

		// Copy assets
		do {
			let assetsDirectory = try sourceDirectory.subfolder(at: "assets")
			try assetsDirectory.copy(to: buildDirectory)
		} catch is FilesError<LocationErrorReason> {
			// no assets to copy just create the directory
			_ = try buildDirectory.createSubfolder(at: "assets")
		}
        
        // Construct render environment
        let environment: Environment
        do {
            let templatePath = try sourceDirectory.subfolder(named:"templates").path
            let fileSystemLoader = FileSystemLoader(paths: [Path(templatePath)])
            environment = Environment(loader: fileSystemLoader)
        } catch is FilesError<LocationErrorReason> {
            // No templates for you
            environment = Environment()
        }

		// Render templates
		let files = pagesDirectory.files.recursive
		for file in files {
			// Determine where to render
			var targetDirectory = buildDirectory
			if file.nameExcludingExtension != "index" {
				let targetPath = file.path(relativeTo: pagesDirectory)
					.split(separator: ".")
					.dropLast()
					.joined()
				targetDirectory = try buildDirectory.createSubfolder(at: targetPath)
			}

			// Build data object
			let uri = "/\(targetDirectory.path(relativeTo: buildDirectory))"
			let rootPath = uri != "/"
				? String(repeating: "../", count: uri.count(of: Character("/")))
				: "./"

			let data = TemplateData(
				site: TemplateSiteData(
					title: config.title,
					description: config.description,
                    image: config.image != nil ? "\(rootPath)assets/\(config.image!)" : nil,
					root: rootPath,
					assets: "\(rootPath)assets/"
				),
				page: TemplatePageData(
					title: uri == "/" ? "Index" : targetDirectory.name.titleified,
					path: uri,
					content: nil
				)
			)

			// Render template
			let targetFile = try targetDirectory.createFile(at: "index.html")
            let pageContent: String
            
            switch file.extension?.lowercased() {
            case "markdown", "md":
                pageContent = try renderMarkdownTemplate(from: file)
            case "html":
                pageContent = try renderStencilTemplate(environment: environment, from: file, data: data)
            default:
                throw BuilderError.unrecognizedTemplate(file.name)
            }
            
            let content = try environment.renderTemplate(string: layoutTemplate, context: [
                "site": data.site.dictionary as Any,
                "page": [
                    "title": data.page.title,
                    "path": uri,
                    "content": pageContent
                ],
            ])

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
            configString = try directory.file(at: "site.yaml").readAsString()
        } else if directory.containsFile(named: "site.yml") {
            configString = try directory.file(at: "site.yml").readAsString()
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
    private func renderStencilTemplate(environment: Environment, from file: File, data: TemplateData) throws -> String {
		let fileContents = try file.readAsString()
        
        return try environment.renderTemplate(string: fileContents, context: [
			"site": data.site.dictionary as Any,
			"page": data.page.dictionary as Any,
		])
	}
}

public enum BuilderError: Error, Equatable {
	case missingLayoutTemplate
	case missingPagesDirectory
	case missingSiteConfig
    case unrecognizedTemplate(String)
}

public struct TemplateSiteData: Codable {
	public let title: String
	public let description: String?
    public let image: String?
	public let root: String
	public let assets: String
}

public struct TemplatePageData: Codable {
	public let title: String
	public let path: String
	public let content: String?
}

public struct TemplateData: Codable {
	public let site: TemplateSiteData
	public let page: TemplatePageData
}
