/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Files
import Foundation

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
            let targetDirectory = arguments.count > 2
                ? try makeWorkingDirectory(arguments[2])
                : Folder.current
            try Generator.generate(target: targetDirectory)

		case "build":
            let sourceDirectory = try getWorkingDirectory(
                arguments.count > 2
                    ? arguments[2]
                    : nil
            )
            let renderer = try Renderer(source: sourceDirectory)

            let targetDirectory = try makeWorkingDirectory(
                arguments.count > 3
                    ? arguments[3]
                    : sourceDirectory.path + "/build"
            )

            let builder = Builder(source: sourceDirectory, renderer: renderer)
            try builder.build(target: targetDirectory)

		case "serve":
			let sourceDirectory = try getWorkingDirectory(
                arguments.count > 2
                    ? arguments[2]
                    : nil
            )
            let renderer = try Renderer(source: sourceDirectory)

            let server = Server(source: sourceDirectory, renderer: renderer)
            try server.start()

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
    
    /// Get directory to work in, creating it if it doesn't exist.
    ///
    /// - Parameter path: Path to the folder to create.
    /// - Returns: Working directory.
    private func makeWorkingDirectory(_ path: String) throws -> Folder {
        do {
            return try Folder(path: path)
        } catch is FilesError<LocationErrorReason> {
            let fileManager = FileManager()
            try fileManager.createDirectory(
                atPath: path,
                withIntermediateDirectories: true
            )
        }
        
        return try Folder(path: path) // this should work now
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
