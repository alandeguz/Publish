/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing
import Publish
import Codextended

final class PathTests: PublishTestCase {
    @Test func `Absolute String`() {
        #expect((Path("relative").absoluteString) == ("/relative/"))
        #expect((Path("/absolute").absoluteString) == ("/absolute"))
    }

    @Test func `Appending Component`() {
        let path = Path("one")
        #expect((path.appendingComponent("two")) == ("one/two"))
    }

    @Test func `String Interpolation`() {
        let path = Path("my/path")
        #expect(("\(path)") == ("my/path"))
    }

    @Test func `Coding`() throws {
        struct Wrapper: Equatable, Codable {
            let path: Path
        }

        let wrapper = Wrapper(path: Path("my/path"))
        let data = try wrapper.encoded()
        #expect((wrapper) == (try data.decoded()))
    }
}
