/**
 *  Heimdall
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Files
import Foundation
import Mustache

public struct Builder {
	private let config: SiteConfig
	private let siteDirectory: Folder
	private let layoutTemplate: Template

	public init(basedOn path: String?) throws {
		do {
			self.siteDirectory = path != nil
				? try Folder(path: path!)
				: Folder.current
		} catch is FilesError<LocationErrorReason> {
			throw BuilderError.missingSiteDirectory
		}

		do {
			let configText = try siteDirectory.file(at: "site.yml")
				.readAsString()

			self.config = try parseConfig(from: configText)

		} catch is FilesError<LocationErrorReason> {
			throw BuilderError.missingSiteConfig
		}

		do {
			let layoutString = try siteDirectory.file(at: "layout.mustache")
				.readAsString()
			layoutTemplate = try Template(string: layoutString)
		} catch is FilesError<LocationErrorReason> {
			throw BuilderError.missingLayoutTemplate
		}
	}

	public func build() throws {
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
		var indexFound = false
		for file in files {
			// Determine where to render
			var targetDirectory = buildDirectory
			if file.nameExcludingExtension != "index" {
				let targetPath = file.path(relativeTo: pagesDirectory)
					.split(separator: ".")
					.dropLast()
					.joined()
				targetDirectory = try buildDirectory.createSubfolder(at: targetPath)
			} else {
				indexFound = true
			}

			// Build data object
			let uri = "/\(targetDirectory.path(relativeTo: buildDirectory))"
			let rootPath = uri != "/"
				? String(repeating: "../", count: uri.count(of: Character("/")))
				: "./"

			let data = TemplateData(
				site: TemplateSiteData(
					title: self.config.title,
					description: self.config.description,
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
			let content = try renderTemplate(from: file, data: data)

			try targetFile.write(content)
		}

		guard indexFound else {
			throw BuilderError.missingIndexTemplate
		}
	}

	public func renderTemplate(from file: File, data: TemplateData) throws -> String {
		let fileContents = try file.readAsString()
		let template = try Template(string: fileContents)

		let content = try template.render([
			"site": data.site.dictionary,
			"page": data.page.dictionary,
		])

		var pageData = data.page
		pageData.content = content

		return try layoutTemplate.render([
			"site": data.site.dictionary,
			"page": pageData.dictionary,
		])
	}
}

public enum BuilderError: Error {
	case missingIndexTemplate
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
	public var content: String?
}

public struct TemplateData: Codable {
	public let site: TemplateSiteData
	public let page: TemplatePageData
}
