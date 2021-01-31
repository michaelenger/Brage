/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Files
import Foundation
import Mustache

public struct Builder {
    public func build(fromSource sourcePath: String?) throws {
        let siteDirectory: Folder
        do {
            siteDirectory = sourcePath != nil
                ? try Folder(path: sourcePath!)
                : Folder.current
        } catch is FilesError<LocationErrorReason> {
            throw BuilderError.missingSiteDirectory
        }

        let config: SiteConfig
        do {
            let configText = try siteDirectory.file(at: "site.yml")
                .readAsString()

            config = try parseConfig(from: configText)

        } catch is FilesError<LocationErrorReason> {
            throw BuilderError.missingSiteConfig
        }

        let layoutTemplate: Template
        do {
            let layoutString = try siteDirectory.file(at: "layout.mustache")
                .readAsString()
            layoutTemplate = try Template(string: layoutString)
        } catch is FilesError<LocationErrorReason> {
            throw BuilderError.missingLayoutTemplate
        }

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
            let pageContent = try renderMustacheTemplate(from: file, data: data)
            
            let content = try layoutTemplate.render([
                "site": data.site.dictionary,
                "page": [
                    "title": data.page.title,
                    "path": uri,
                    "content": pageContent
                ],
            ])

			try targetFile.write(content)
		}
	}

	public func renderMustacheTemplate(from file: File, data: TemplateData) throws -> String {
		let fileContents = try file.readAsString()
		let template = try Template(string: fileContents)

		return try template.render([
			"site": data.site.dictionary,
			"page": data.page.dictionary,
		])
	}
}

public enum BuilderError: Error {
	case missingLayoutTemplate
	case missingPagesDirectory
	case missingSiteDirectory
	case missingSiteConfig
}

public struct TemplateSiteData: Codable {
	public let title: String
	public let description: String?
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
