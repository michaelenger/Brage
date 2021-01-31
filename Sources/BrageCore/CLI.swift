/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

public struct CLI {
	public init() {}

	public func run(arguments: [String] = CommandLine.arguments) throws {
		guard arguments.count > 1 else {
			return showHelp()
		}

		let siteDirectory = arguments.count > 2 ? arguments[2] : nil

		switch arguments[1] {
		case "new":
			print("TODO")
		case "build":
			let builder = Builder()
            try builder.build(fromSource: siteDirectory)
		case "serve":
			print("TODO")
		default:
			showHelp()
		}
	}
        
	private func showHelp() {
		print("""
		Brage

		USAGE: Brage [command]

		Available commands:
		- new: Set up a new site with some example data.
		- build: Generate a site.
		- serve: Generate the site and run a localhost server which hosts it.
		""")
	}
}
