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

final class PodcastFeedGenerationTests: PublishTestCase {
    @Test func `Only Including Specified Section`() async throws {
        let folder = try Folder.createTemporary()

        try await generateFeed(in: folder, content: [
            "one/a.md": """
            \(makeStubbedAudioMetadata())
            # Included
            """,
            "two/b": "# Not included"
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
                "one/a.md": """
                \(makeStubbedAudioMetadata())
                # Included
                """,
                "one/b.md": "# Not included"
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
            \(makeStubbedAudioMetadata())
            BEGIN [Link](/page) ![Image](/image.png) [Link](https://apple.com) END
            """
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()
        let substring = feed.substrings(between: "BEGIN ", and: " END").first

        #expect((substring) == ("""
        <a href="https://swiftbysundell.com/page">Link</a> \
        <img src=\"https://swiftbysundell.com/image.png\" alt=\"Image\"> \
        <a href="https://apple.com">Link</a>
        """))
    }

    @Test func `Item Prefix And Suffix`() async throws {
        let folder = try Folder.createTemporary()

        let prefixSuffix = """
        rss.titlePrefix: Prefix
        rss.titleSuffix: Suffix
        """

        try await generateFeed(in: folder, content: [
            "one/item.md": """
            \(makeStubbedAudioMetadata(including: prefixSuffix))
            # Title
            """
        ])

        let feed = try folder.file(at: "Output/feed.rss").readAsString()
        #expect(feed.contains("<title>PrefixTitleSuffix</title>"))
    }

    @Test func `Reusing Previous Feed If No Items Were Modified`() async throws {
        let folder = try Folder.createTemporary()
        let contentFile = try folder.createFile(at: "Content/one/item.md")
        try contentFile.write(makeStubbedAudioMetadata())

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
        let contentFile = try folder.createFile(at: "Content/one/item.md")
        try contentFile.write(makeStubbedAudioMetadata())

        try await generateFeed(in: folder)
        let feedA = try folder.file(at: "Output/feed.rss").readAsString()

        var newConfig = try makeConfigStub()
        newConfig.author.name = "New author name"
        let newDate = Constants.today.addingTimeInterval(60 * 60)
        try await generateFeed(in: folder, config: newConfig, date: newDate)
        let feedB = try folder.file(at: "Output/feed.rss").readAsString()

        #expect((feedA) != (feedB))
    }

    @Test func `Not Reusing Previous Feed If Item Was Added`() async throws {
        let folder = try Folder.createTemporary()

        let audio = Audio(
            url: try #require(URL(string: "https://audio.mp3")),
            duration: Audio.Duration(),
            byteSize: 55
        )

        let itemA = Item<Site>(
            path: "a",
            sectionID: .one,
            metadata: .init(podcast: .init()),
            content: Content(audio: audio)
        )

        let itemB = Item<Site>(
            path: "b",
            sectionID: .one,
            metadata: .init(podcast: .init()),
            content: Content(
                lastModified: itemA.lastModified,
                audio: audio
            )
        )

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

private extension PodcastFeedGenerationTests {
    typealias Site = WebsiteStub.WithPodcastMetadata
    typealias Configuration = PodcastFeedConfiguration<Site>

    func makeConfigStub() throws -> Configuration {
        Configuration(
            targetPath: .defaultForRSSFeed,
            imageURL: try #require(URL(string: "image.png")),
            copyrightText: "John Appleseed 2019",
            author: PodcastAuthor(
                name: "John Appleseed",
                emailAddress: "john.appleseed@apple.com"
            ),
            description: "Description",
            subtitle: "Subtitle",
            category: "Category"
        )
    }

    func makeStubbedAudioMetadata(including additionalString: String = "") -> String {
        """
        ---
        audio.url: https://audio.mp3
        audio.duration: 05:02
        audio.size: 12345
        \(additionalString)
        ---
        """
    }

    func generateFeed(
        in folder: Folder,
        config: Configuration? = nil,
        itemPredicate: Publish.Predicate<Item<Site>>? = nil,
        generationSteps: [PublishingStep<Site>] = [
            .addMarkdownFiles()
        ],
        date: Date = Constants.today,
        content: [Path : String] = [:]
    ) async throws {
        try await publishWebsiteWithPodcast(in: folder, using: [
            .group(generationSteps),
            .generatePodcastFeed(
                for: .one,
                itemPredicate: itemPredicate,
                config: config ?? makeConfigStub(),
                date: date
            )
        ], content: content)
    }
}
