/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Files

public struct CLI {
	public init() {}

    /// Run the CLI application.
    ///
    /// - Parameter arguments: Command-line arguments.
	public func run(arguments: [String] = CommandLine.arguments) throws {
		guard arguments.count > 1 else {
			return showHelp()
		}

		switch arguments[1] {
		case "new":
			print("TODO")
		case "build":
            let siteDirectory = try getWorkingDirectory(arguments.count > 2 ? arguments[2] : nil)
            
			let builder = Builder()
            try builder.build(source: siteDirectory)
		case "serve":
			print("TODO")
		default:
			showHelp()
		}
	}
    
    /// Get directory to work in, defaulting to the current directory if no path is passed.
    ///
    /// - Parameter path: Path to the folder to get.
    /// - Returns: Working directory.
    private func getWorkingDirectory(_ path: String?) throws -> Folder {
        do {
            return path != nil
                ? try Folder(path: path!)
                : Folder.current
        } catch is FilesError<LocationErrorReason> {
            throw CLIError.missingSiteDirectory
        }
    }
    
    /// Display the help text.
	private func showHelp() {
		print("""
		Brage

		USAGE: Brage [command] [site_directory]

		Available commands:
		- new: Set up a new site with some example data.
		- build: Generate a site.
		- serve: Generate the site and run a localhost server which hosts it.
		""")
	}
}

public enum CLIError: Error, Equatable {
    case missingSiteDirectory
}
