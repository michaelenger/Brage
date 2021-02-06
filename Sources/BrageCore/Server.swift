/**
*  Brage
*  Copyright (c) Michael Enger 2021
*  MIT license, see LICENSE file for details
*/

import Dispatch
import Files
import Swifter

/// Server which provides the templates as compiled HTML.
public struct Server {
    let server: HttpServer
    let sourceDirectory: Folder
    
    /// Initialize the server with the specified source directory.
    ///
    /// - Parameter source: Site directory to serve files from.
    public init(source: Folder) {
        self.server = HttpServer()
        self.sourceDirectory = source
        
        if source.containsSubfolder(named: "assets") {
            server["/assets/:path"] = shareFilesFromDirectory("\(source.path)/assets")
        }
        // Match any long possible route. This is not the ideal way to handle this, but it's a known limitation of Swifter.
        // TODO: Change this when this issue is solved: https://github.com/httpswift/swifter/issues/405
        server["/*/*/*/*/*/*/*"] = respond
        server["/*/*/*/*/*/*"] = respond
        server["/*/*/*/*/*"] = respond
        server["/*/*/*/*"] = respond
        server["/*/*/*"] = respond
        server["/*/*"] = respond
        server["/*"] = respond
        server["/"] = respond
    }
    
    /// Start the server, listening for requests at the specified port.
    ///
    /// - Parameter port: Port to listen at.
    public func start(port: UInt16 = 8080) throws {
        let semaphore = DispatchSemaphore(value: 0)
        do {
            try server.start(port, forceIPv4: true)
            semaphore.wait()
        } catch {
            semaphore.signal() // probably useless, but feels correct
            throw ServerError.serverStartError(error.localizedDescription)
        }
    }
    
    /// Respond to a request.
    ///
    /// - Parameter request: HTTP request to respond to.
    /// - Returns: HTTP response.
    private func respond(request: HttpRequest) -> HttpResponse {
        let targetFile: String = request.path == "/"
            ? "pages/index.html"
            : "pages\(request.path).html"
    
        do {
            let fileContents = try sourceDirectory.file(at: targetFile).readAsString()
            return .ok(.html(fileContents))
        } catch is FilesError<LocationErrorReason> {
            return .notFound
        } catch {
            print("Unhandled error: \(error)")
            return .internalServerError
        }
    }
}

public enum ServerError: Error, Equatable {
    case serverStartError(String)
}
