/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Files
import XCTest
@testable import BrageCore

final class CLITests: XCTestCase {
    func testMissingSiteDirectory() throws {
        let cli = CLI()
        do {
            try cli.run(arguments: ["TEST", "build", "\(Folder.temporary)doesnotexist"])
        } catch let e as CLIError {
            XCTAssertEqual(e, CLIError.missingSiteDirectory)
        }
    }
}
