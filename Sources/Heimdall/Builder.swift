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
		// Clear and create build directory
		do {
			let buildDirectory = try siteDirectory.subfolder(at: "build")
			try buildDirectory.delete()
		} catch is FilesError<LocationErrorReason> {
			// this is fine 🔥
		}
		let buildDirectory = try siteDirectory.createSubfolder(at: "build")

		// Render index template
		do {
			let indexTemplate = try siteDirectory.file(at: "index.mustache")
			let targetFile = try buildDirectory.createFile(at: "index.html")
			let content = try renderTemplate(from: indexTemplate)

			try targetFile.write(content)
		} catch is FilesError<LocationErrorReason> {
			throw BuilderError.missingIndexTemplate
		}

		// Render other templates
		// TODO
	}

	private func renderTemplate(from file: File) throws -> String {
		let fileContents = try file.readAsString()
		let template = try Template(string: fileContents)

		let content = try template.render([
			"site": self.config.dictionary
		])

		return try layoutTemplate.render([
			"site": self.config.dictionary,
			"page": [
				"content": content
			]
		])
	}
}

public enum BuilderError: Error {
	case missingIndexTemplate
	case missingLayoutTemplate
	case missingSiteDirectory
	case missingSiteConfig
}
