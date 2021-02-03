/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Files
import Foundation
import Ink
import Stencil

public struct Builder {
    /// Build a site based on a site directory.
    ///
    /// - Parameter fromSource: Path to the directory of the site to build.
    public func build(fromSource sourcePath: String?) throws {
        let siteDirectory: Folder
        do {
            siteDirectory = sourcePath != nil
                ? try Folder(path: sourcePath!)
                : Folder.current
        } catch is FilesError<LocationErrorReason> {
            throw BuilderError.missingSiteDirectory
        }

        let config = try loadConfig(from: siteDirectory)
        let layoutTemplate = try loadLayoutTemplate(from: siteDirectory)

		// Get the pages directory
		let pagesDirectory: Folder
		do {
			pagesDirectory = try siteDirectory.subfolder(at: "pages")
		} catch is FilesError<LocationErrorReason> {
			throw BuilderError.missingPagesDirectory
		}

		// Clear and create build directory
		do {
			let buildDirectory = try siteDirectory.subfolder(at: "build")
			try buildDirectory.delete()
		} catch is FilesError<LocationErrorReason> {
			// this is fine 🔥
		}
		let buildDirectory = try siteDirectory.createSubfolder(at: "build")

		// Copy assets
		do {
			let assetsDirectory = try siteDirectory.subfolder(at: "assets")
			try assetsDirectory.copy(to: buildDirectory)
		} catch is FilesError<LocationErrorReason> {
			// no assets to copy just create the directory
			_ = try buildDirectory.createSubfolder(at: "assets")
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
                pageContent = try renderStencilTemplate(from: file, data: data)
            default:
                throw BuilderError.unrecognizedTemplate(file.name)
            }
            
            let content = try layoutTemplate.render([
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
        
        return try parseConfig(from: configString)
    }
    
    /// Load the layout Stencil template from the specified site directory.
    ///
    /// - Parameter from: Site directory to load the template from.
    /// - Returns: A stencil template.
    private func loadLayoutTemplate(from directory: Folder) throws -> Template {
        let layoutString: String
        if directory.containsFile(named: "layout.html") {
            layoutString = try directory.file(at: "layout.html").readAsString()
        } else {
            throw BuilderError.missingLayoutTemplate
        }
        
        return Template(templateString: layoutString)
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
    /// - Parameter file: File to read and render from.
    /// - Parameter data: Data to send to the template.
    /// - Returns: Rendered HTML content.
	private func renderStencilTemplate(from file: File, data: TemplateData) throws -> String {
		let fileContents = try file.readAsString()
		let template = Template(templateString: fileContents)

		return try template.render([
			"site": data.site.dictionary as Any,
			"page": data.page.dictionary as Any,
		])
	}
}

public enum BuilderError: Error, Equatable {
	case missingLayoutTemplate
	case missingPagesDirectory
	case missingSiteDirectory
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
