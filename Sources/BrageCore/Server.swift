/**
*  Brage
*  Copyright (c) Michael Enger 2021
*  MIT license, see LICENSE file for details
*/

import Dispatch
import Files
import Foundation
import Swifter

/// Server which provides the templates as compiled HTML.
public struct Server {
    let renderer: Renderer
    let server: HttpServer
    let sourceDirectory: Folder

    /// Initialize the server with the specified source directory.
    ///
    /// - Parameter source: Site directory to serve files from.
    public init(source: Folder, renderer: Renderer) {
        self.renderer = renderer
        self.server = HttpServer()
        self.sourceDirectory = source

        // Match any long possible route. This is not the ideal way to handle this, but it's a known limitation of Swifter.
        // TODO: Change this when this issue is solved: https://github.com/httpswift/swifter/issues/405

        if source.containsSubfolder(named: "assets") {
            server["/assets/*/*/*/*/*/*"] = asset
            server["/assets/*/*/*/*/*"] = asset
            server["/assets/*/*/*/*"] = asset
            server["/assets/*/*/*"] = asset
            server["/assets/*/*"] = asset
            server["/assets/*"] = asset
        }

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
        Logger.debug("Starting server for \(sourceDirectory.path) at localhost:\(port)")

        let semaphore = DispatchSemaphore(value: 0)
        do {
            try server.start(port, forceIPv4: true)
            semaphore.wait()
        } catch {
            semaphore.signal() // probably useless, but feels correct
            throw ServerError.serverStartError(error.localizedDescription)
        }
    }
    
    private func asset(request: HttpRequest) -> HttpResponse {
        let filePath = sourceDirectory.path + request.path.removingPercentEncoding!
        if let file = try? filePath.openForReading() {
            let mimeType = request.path.mimeType()
            var responseHeader: [String: String] = ["Content-Type": mimeType]

            if let attr = try? FileManager.default.attributesOfItem(atPath: filePath),
                let fileSize = attr[FileAttributeKey.size] as? UInt64 {
                responseHeader["Content-Length"] = String(fileSize)
            }

            Logger.debug("Serving asset: \(request.path)")
            return .raw(200, "OK", responseHeader, { writer in
                try? writer.write(file)
                file.close()
            })
        }
        
        Logger.error("No asset found for: \(request.path)")
        return .notFound
    }

    /// Respond to a request.
    ///
    /// - Parameter request: HTTP request to respond to.
    /// - Returns: HTTP response.
    private func respond(request: HttpRequest) -> HttpResponse {
        Logger.debug("Received request for \(request.path)")

        let targetFile: String = request.path == "/"
            ? "pages/index"
            : "pages" + request.path.trimSuffix("/")

        do {
            var file: File? = nil
            for ext in RendererFileExtensions.allCases {
                if sourceDirectory.containsFile(at: "\(targetFile).\(ext.rawValue)") {
                    file = try sourceDirectory.file(at: "\(targetFile).\(ext.rawValue)")
                    break
                }
            }

            guard file != nil else {
                Logger.error("No template found for: \(request.path)")
                return .notFound
            }

            let relativePath = file!.path(relativeTo: sourceDirectory)
            Logger.debug("Serving file: \(relativePath)")

            let contents = try renderer.render(file: file!, uri: request.path)
            return .ok(.html(contents))
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
