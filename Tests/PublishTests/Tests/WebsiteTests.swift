/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Testing
import Publish

final class WebsiteTests: PublishTestCase {
    private var website = WebsiteStub.WithoutItemMetadata()

    @Test func `Default Tag List Path`() {
        #expect((website.tagListPath) == ("tags"))
    }

    @Test func `Custom Tag List Path`() {
        website.tagHTMLConfig = TagHTMLConfiguration(basePath: "custom")
        #expect((website.tagListPath) == ("custom"))
    }

    @Test func `Path For Section ID`() {
        #expect((website.path(for: .one)) == ("one"))
    }
    
    @Test func `Path For Section ID With Raw Value`() {
        #expect((website.path(for: .customRawValue)) == ("custom-raw-value"))
    }

    @Test func `Default Path For Tag`() {
        let tag = Tag("some tag")
        #expect((website.path(for: tag)) == ("tags/some-tag"))
    }

    @Test func `Custom Path For Tag`() {
        website.tagHTMLConfig = TagHTMLConfiguration(basePath: "custom")
        let tag = Tag("some tag")
        #expect((website.path(for: tag)) == ("custom/some-tag"))
    }

    @Test func `Default URL For Tag`() {
        #expect((website.url(for: Tag("some tag"))) == (URL(string: "https://swiftbysundell.com/tags/some-tag")))
    }

    @Test func `Custom URL For Tag`() {
        website.tagHTMLConfig = TagHTMLConfiguration(basePath: "custom")

        #expect((website.url(for: Tag("some tag"))) == (URL(string: "https://swiftbysundell.com/custom/some-tag")))
    }

    @Test func `URL For Relative Path`() {
        #expect((website.url(for: Path("a/path"))) == (URL(string: "https://swiftbysundell.com/a/path")))
    }

    @Test func `URL For Absolute Path`() {
        #expect((website.url(for: Path("/a/path"))) == (URL(string: "https://swiftbysundell.com/a/path")))
    }

    @Test func `URL For Location`() {
        let page = Page(path: "mypage", content: Content())

        #expect((website.url(for: page)) == (URL(string: "https://swiftbysundell.com/mypage")))
    }
}
