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
	}

	public func build() throws {
		var indexTemplate: String = ""
		do {
			indexTemplate = try siteDirectory.file(at: "index.mustache")
				.readAsString()
		} catch is FilesError<LocationErrorReason> {
			throw BuilderError.missingIndexTemplate
		}

		// Clear and create build directory
		do {
			let buildDirectory = try siteDirectory.subfolder(at: "build")
			try buildDirectory.delete()
		} catch is FilesError<LocationErrorReason> {
			// this is fine 🔥
		}
		let buildDirectory = try siteDirectory.createSubfolder(at: "build")

		// Render index template
		let targetFile = try buildDirectory.createFile(at: "index.html")
		let content = try renderTemplate(from: indexTemplate)
		try targetFile.write(content)
	}

	private func renderTemplate(from source: String) throws -> String {
		let template = try Template(string: source)

		let data = [
			"site": self.config.dictionary
		]

		return try template.render(data)
	}
}

public enum BuilderError: Error {
	case missingIndexTemplate
	case missingSiteDirectory
	case missingSiteConfig
}
