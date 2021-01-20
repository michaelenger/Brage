/**
 *  Heimdall
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Files
import Foundation

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
			let configText = try File(path: "\(siteDirectory.path)site.yml")
				.readAsString()

			self.config = try parseConfig(from: configText)

		} catch is FilesError<LocationErrorReason> {
			throw BuilderError.missingSiteConfig
		}

		print(config)
	}

	public func build(at path: String) {
		// TODO
	}
}

public enum BuilderError: Error {
	case missingSiteDirectory
	case missingSiteConfig
}
