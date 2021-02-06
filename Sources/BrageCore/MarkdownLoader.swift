/**
*  Brage
*  Copyright (c) Michael Enger 2021
*  MIT license, see LICENSE file for details
*/

import Files
import Ink
import Stencil

/// File system Stencil template loader with support for Markdown files.
class MarkdownLoader: Loader {
    let sourceDirectory: Folder
    
    /// Initialize the loader with the directory to find the templates in.
    ///
    /// - Parameter templateDirectory: Directory to find Markdown templates in.
    public init(templateDirectory: Folder) {
        self.sourceDirectory = templateDirectory
    }
    
    /// Load the Mustache template.
    ///
    /// - Parameter name: Name of the template to load.
    /// - Parameter environment: Environment to load the template in.
    /// - Returns: Loaded stencil template.
    func loadTemplate(name: String, environment: Environment) throws -> Template {
        let file: File
        do {
            file = try sourceDirectory.file(at: name)
        } catch is FilesError<LocationErrorReason> {
            throw TemplateDoesNotExist(templateNames: [name], loader: self)
        }
        
        let fileContents = try file.readAsString()
        let templateString: String
        
        switch file.extension?.lowercased() {
        case "markdown", "md":
            let parser = MarkdownParser()
            templateString = parser.html(from: fileContents)
        default:
            templateString = fileContents // we basic
        }
        
        return Template(templateString: templateString, environment: environment)
    }
}
