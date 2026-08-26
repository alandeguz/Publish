/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Testing
import Publish
import Files
import Sweep

final class RSSFeedGenerationTests: PublishTestCase {
    @Test func `Only Including Specified Sections`() async throws {
        let folder = try Folder.createTemporary()

        try await generateFeed(in: folder, content: [
            "one/a.md": "Included",
            "two/b.md": "Not included"
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()
        #expect(feed.contains("Included"))
        #expect(!(feed.contains("Not included")))
    }

    @Test func `Only Including Items Matching Predicate`() async throws {
        let folder = try Folder.createTemporary()

        try await generateFeed(
            in: folder,
            itemPredicate: \.path == "one/a",
            content: [
                "one/a.md": "Included",
                "one/b.md": "Not included"
            ]
        )

        let feed = try folder.file(at: "Output/feed.rss").readAsString()
        #expect(feed.contains("Included"))
        #expect(!(feed.contains("Not included")))
    }

    @Test func `Converting Relative Links To Absolute`() async throws {
        let folder = try Folder.createTemporary()

        try await generateFeed(in: folder, content: [
            "one/item.md": """
            BEGIN [Link](/page) ![Image](/image.png) [Link](https://apple.com) END
            """
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()
        let substring = feed.firstSubstring(between: "BEGIN ", and: " END")

        #expect((substring) == ("""
        <a href="https://swiftbysundell.com/page">Link</a> \
        <img src=\"https://swiftbysundell.com/image.png\" alt=\"Image\"> \
        <a href="https://apple.com">Link</a>
        """))
    }

    @Test func `Item Title Prefix And Suffix`() async throws {
        let folder = try Folder.createTemporary()

        try await generateFeed(in: folder, content: [
            "one/item.md": """
            ---
            rss.titlePrefix: Prefix
            rss.titleSuffix: Suffix
            ---
            # Title
            """
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()
        #expect(feed.contains("<title>PrefixTitleSuffix</title>"))
    }

    @Test func `Item Body Prefix And Suffix`() async throws {
        let folder = try Folder.createTemporary()

        try await generateFeed(in: folder, content: [
            "one/item.md": """
            ---
            rss.bodyPrefix: Prefix
            rss.bodySuffix: Suffix
            ---
            Body
            """
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()

        #expect(feed.contains("""
        <content:encoded><![CDATA[Prefix<p>Body</p>Suffix]]></content:encoded>
        """))
    }

    @Test func `Custom Item Link`() async throws {
        let folder = try Folder.createTemporary()

        try await generateFeed(in: folder, content: [
            "one/item.md": """
            ---
            rss.link: custom.link
            ---
            Body
            """
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()

        #expect(feed.contains("<link>custom.link</link>"))

        #expect(feed.contains("""
        <guid isPermaLink="false">https://swiftbysundell.com/one/item</guid>
        """))
    }

    @Test func `Reusing Previous Feed If No Items Were Modified`() async throws {
        let folder = try Folder.createTemporary()
        let contentFile = try folder.createFile(at: "Content/one/item.md")

        try await generateFeed(in: folder)
        let feedA = try folder.file(at: "Output/feed.rss").readAsString()

        let newDate = Constants.today.addingTimeInterval(60 * 60)
        try await generateFeed(in: folder, date: newDate)
        let feedB = try folder.file(at: "Output/feed.rss").readAsString()

        #expect((feedA) == (feedB))

        try contentFile.append("New content")
        try await generateFeed(in: folder, date: newDate)
        let feedC = try folder.file(at: "Output/feed.rss").readAsString()

        #expect((feedB) != (feedC))
    }

    @Test func `Not Reusing Previous Feed If Config Changed`() async throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(at: "Content/one/item.md")

        try await generateFeed(in: folder)
        let feedA = try folder.file(at: "Output/feed.rss").readAsString()

        let newConfig = RSSFeedConfiguration(ttlInterval: 5000)
        let newDate = Constants.today.addingTimeInterval(60 * 60)
        try await generateFeed(in: folder, config: newConfig, date: newDate)
        let feedB = try folder.file(at: "Output/feed.rss").readAsString()

        #expect((feedA) != (feedB))
    }

    @Test func `Not Reusing Previous Feed If Item Was Added`() async throws {
        let folder = try Folder.createTemporary()
        let itemA = Item.stub()
        let itemB = Item.stub().setting(\.lastModified, to: itemA.lastModified)

        try await generateFeed(in: folder, generationSteps: [
            .addItem(itemA)
        ])

        let feedA = try folder.file(at: "Output/feed.rss").readAsString()

        try await generateFeed(in: folder, generationSteps: [
            .addItem(itemA),
            .addItem(itemB)
        ])

        let feedB = try folder.file(at: "Output/feed.rss").readAsString()
        #expect((feedA) != (feedB))
    }
}

private extension RSSFeedGenerationTests {
    typealias Site = WebsiteStub.WithoutItemMetadata

    func generateFeed(
        in folder: Folder,
        config: RSSFeedConfiguration = .default,
        itemPredicate: Publish.Predicate<Item<Site>>? = nil,
        generationSteps: [PublishingStep<Site>] = [
            .addMarkdownFiles()
        ],
        date: Date = Constants.today,
        content: [Path : String] = [:]
    ) async throws {
        try await publishWebsite(in: folder, using: [
            .group(generationSteps),
            .generateRSSFeed(
                including: [.one],
                itemPredicate: itemPredicate,
                config: config,
                date: date
            )
        ], content: content)
    }
}
