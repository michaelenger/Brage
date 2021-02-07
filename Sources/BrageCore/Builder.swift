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

/// Builder which renderers all templates in a source directory.
public struct Builder {
    let renderer: Renderer
    let sourceDirectory: Folder
    
    /// Initialize the builder with a source directory and renderer.
    ///
    /// - Parameter source: Directory to base builder on.
    /// - Parameter renderer: Renderer to use when rendering the templates.
    public init(source sourceDirectory: Folder, renderer: Renderer) {
        self.renderer = renderer
        self.sourceDirectory = sourceDirectory
    }
    
    /// Build a site based on a site directory.
    ///
    /// - Parameter target: Destination for the rendered HTML files.
    public func build(target targetDirectory: Folder) throws {
        Logger.debug("Building site from \(sourceDirectory.path) to \(targetDirectory.path)")

        // Get the pages directory
		let pagesDirectory: Folder
		do {
			pagesDirectory = try sourceDirectory.subfolder(named: "pages")
		} catch is FilesError<LocationErrorReason> {
			throw BuilderError.missingPagesDirectory
		}

		// Copy assets
		do {
			let assetsDirectory = try sourceDirectory.subfolder(named: "assets")
            if targetDirectory.containsSubfolder(named: "assets") {
                try targetDirectory.subfolder(named: "assets").delete()
            }
            
            Logger.debug("Copying assets...")
			try assetsDirectory.copy(to: targetDirectory)
		} catch is FilesError<LocationErrorReason> {
			// No assets to copy
		}

        Logger.debug("Rendering pages...")
        
		// Render all page
		let files = pagesDirectory.files.recursive
		for file in files {
			// Determine where to render
			var currentDirectory = targetDirectory
			if file.nameExcludingExtension != "index" {
				let targetPath = file.path(relativeTo: pagesDirectory)
					.split(separator: ".")
					.dropLast()
					.joined()
				currentDirectory = try targetDirectory.createSubfolder(at: targetPath)
			}

			// Build data object
			let uri = "/\(currentDirectory.path(relativeTo: targetDirectory))"

			// Render template
			let targetFile = try currentDirectory.createFile(named: "index.html")
            let content = try renderer.render(file: file, uri: uri)
            
            Logger.debug("Rendering \(targetFile.path(relativeTo: targetDirectory))")

			try targetFile.write(content)
		}
	}
}

public enum BuilderError: Error, Equatable {
	case missingPagesDirectory
}
