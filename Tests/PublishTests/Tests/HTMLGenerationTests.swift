/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing
import Publish
import Plot
import Files

final class HTMLGenerationTests: PublishTestCase {
    private var htmlFactory = HTMLFactoryMock<WebsiteStub.WithoutItemMetadata>()

    @Test func `Generating Index HTML`() async throws {
        htmlFactory.makeIndexHTML = { content, _ in
            HTML(.body(.text(content.title)))
        }

        try await publishWebsite(
            using: Theme(htmlFactory: htmlFactory),
            content: ["index.md": "# Hello, world!"],
            expectedHTML: ["index.html": "Hello, world!"]
        )
    }

    @Test func `Generating Section HTML`() async throws {
        htmlFactory.makeSectionHTML = { section, _ in
            HTML(.body(.text(section.title)))
        }

        try await publishWebsite(
            using: Theme(htmlFactory: htmlFactory),
            content: [
                "one/index.md": "# Section 1",
                "two/index.md": "# Section 2"
            ],
            expectedHTML: [
                "one/index.html": "Section 1",
                "two/index.html": "Section 2"
            ]
        )
    }

    @Test func `Generating Item HTML`() async throws {
        htmlFactory.makeItemHTML = { item, _ in
            HTML(.body(
                .unwrap(item.audio?.url, { .text($0.absoluteString) }),
                .text(" "),
                .text(item.title)
            ))
        }

        try await publishWebsite(
            using: Theme(htmlFactory: htmlFactory),
            content: [
                "one/a.md": """
                    ---
                    audio.url: a.mp3
                    ---
                    # A
                    """,
                "two/b.md": """
                    ---
                    audio.url: b.mp3
                    ---
                    # B
                    """
            ],
            expectedHTML: [
                "one/a/index.html": "a.mp3 A",
                "two/b/index.html": "b.mp3 B"
            ]
        )
    }

    @Test func `Generating Nested Item HTML`() async throws {
        htmlFactory.makeItemHTML = { item, _ in
            HTML(.body(.text(item.title)))
        }

        try await publishWebsite(
            using: Theme(htmlFactory: htmlFactory),
            content: [
                "one/2019/12/a.md": """
                    # A
                    """,
                "two/2020/01/b.md": """
                    # B
                    """
            ],
            expectedHTML: [
                "one/2019/12/a/index.html": "A",
                "two/2020/01/b/index.html": "B"
            ]
        )
    }

    @Test func `Generating Page HTML`() async throws {
        htmlFactory.makePageHTML = { page, _ in
            HTML(.body(.text(page.title)))
        }

        try await publishWebsite(
            using: Theme(htmlFactory: htmlFactory),
            content: [
                "page1.md": "# Page 1",
                "page2.md": "# Page 2"
            ],
            additionalSteps: [
                .addPage(Page(
                    path: "path/to/page3",
                    content: Content(title: "Page 3")
                ))
            ],
            expectedHTML: [
                "page1/index.html": "Page 1",
                "page2/index.html": "Page 2",
                "path/to/page3/index.html": "Page 3"
            ]
        )
    }

    @Test func `Generating Tag HTML`() async throws {
        htmlFactory.makeTagListHTML = { page, _ in
            HTML(.body(.ul(
                .forEach(page.tags.sorted()) {
                    .li(.text($0.string))
                }
            )))
        }

        htmlFactory.makeTagDetailsHTML = { page, _ in
            HTML(.body(.text(page.tag.string)))
        }

        try await publishWebsite(
            using: Theme(htmlFactory: htmlFactory),
            content: [
                "one/a.md": """
                    ---
                    tags: tag 1
                    ---
                    """,
                "two/b.md": """
                    ---
                    tags: tag 2, tag 3😉
                    ---
                    """
            ],
            expectedHTML: [
                "tags/index.html": """
                <ul><li>tag 1</li><li>tag 2</li><li>tag 3😉</li></ul>
                """,
                "tags/tag-1/index.html": "tag 1",
                "tags/tag-2/index.html": "tag 2",
                "tags/tag-3/index.html": "tag 3😉",
                "one/a/index.html": "",
                "two/b/index.html": ""
            ]
        )
    }

    @Test func `Cleaning Up Old HTML Files`() async throws {
        htmlFactory.makePageHTML = { page, _ in
            HTML(.body(.text(page.title)))
        }

        let folder = try Folder.createTemporary()

        try await publishWebsite(
            in: folder,
            using: Theme(htmlFactory: htmlFactory),
            content: [
                "first.md": "# First"
            ],
            expectedHTML: [
                "first/index.html": "First"
            ]
        )

        try await publishWebsite(
            in: folder,
            using: Theme(htmlFactory: htmlFactory),
            content: [
                "second.md": "# Second"
            ],
            expectedHTML: [
                "second/index.html": "Second"
            ]
        )
    }

    @Test func `Always Generating Index Page For All Sections`() async throws {
        htmlFactory.makeSectionHTML = { section, _ in
            HTML(.body(.text(section.id.rawValue)))
        }

        try await publishWebsite(
            using: Theme(htmlFactory: htmlFactory),
            expectedHTML: [
                "one/index.html": "one",
                "two/index.html": "two",
                "three/index.html": "three",
                "custom-raw-value/index.html": "custom-raw-value"
            ]
        )
    }
    

    @Test func `Not Generating Tag HTML For Incompatible Theme`() async throws {
        htmlFactory.makeTagListHTML = nil
        htmlFactory.makeTagDetailsHTML = nil

        try await publishWebsite(
            using: Theme(htmlFactory: htmlFactory),
            additionalSteps: [
                .addItem(Item.stub(withPath: "item").setting(\.tags, to: ["tag"]))
            ],
            expectedHTML: [
                "index.html": "",
                "one/index.html": "",
                "two/index.html": "",
                "three/index.html": "",
                "custom-raw-value/index.html": "",
                "one/item/index.html": ""
            ],
            allowWhitelistedOutputFiles: false
        )
    }

    @Test func `Not Generating Tag HTML When Disabled`() async throws {
        let site = WebsiteStub.WithoutItemMetadata()
        site.tagHTMLConfig = nil

        try await publishWebsite(site,
            using: Theme(htmlFactory: htmlFactory),
            additionalSteps: [
                .addItem(Item.stub(withPath: "item").setting(\.tags, to: ["tag"]))
            ],
            expectedHTML: [
                "index.html": "",
                "one/index.html": "",
                "two/index.html": "",
                "three/index.html": "",
                "custom-raw-value/index.html": "",
                "one/item/index.html": ""
            ],
            allowWhitelistedOutputFiles: false
        )
    }

    @Test func `Generating Stand Alone HTML Files`() async throws {
        let folder = try Folder.createTemporary()
        let theme = Theme(htmlFactory: htmlFactory)

        try await publishWebsite(in: folder, using: [
            .addItem(Item.stub(withPath: "item").setting(\.tags, to: ["tag"])),
            .addItem(Item.stub(withPath: "rawValueItem", sectionID: .customRawValue).setting(\.tags, to: ["tag"])),
            .generateHTML(withTheme: theme, fileMode: .standAloneFiles)
        ])

        try verifyOutput(
            in: folder,
            expectedHTML: [
                "index.html": "",
                "one/index.html": "",
                "two/index.html": "",
                "three/index.html": "",
                "custom-raw-value/index.html": "",
                "one/item.html": "",
                "custom-raw-value/rawValueItem.html": "",
                "tags/index.html": "",
                "tags/tag.html": ""
            ],
            allowWhitelistedFiles: false
        )
    }

    @Test func `Foundation Theme`() async throws {
        let folder = try Folder.createTemporary()

        try await publishWebsite(
            in: folder,
            using: [
                .addMarkdownFiles(),
                .generateHTML(withTheme: .foundation)
            ],
            content: [
                "one/index.md": "# SectionTitle",
                "one/item.md": """
                ---
                tags: tagA, tagB
                ---
                # ItemTitle
                """,
                "page.md": "# PageTitle"
            ]
        )

        let siteIndex = try folder.file(at: "Output/index.html")
        #expect(try siteIndex.readAsString().contains("WebsiteName"))

        let sectionIndex = try folder.file(at: "Output/one/index.html")
        #expect(try sectionIndex.readAsString().contains("SectionTitle"))

        let item = try folder.file(at: "Output/one/item/index.html")
        #expect(try item.readAsString().contains("ItemTitle"))

        let page = try folder.file(at: "Output/page/index.html")
        #expect(try page.readAsString().contains("PageTitle"))

        let tagList = try folder.file(at: "Output/tags/index.html")
        let tagListHTML = try tagList.readAsString()
        #expect(tagListHTML.contains("tagA"))
        #expect(tagListHTML.contains("tagB"))

        let tagDetails = try folder.file(at: "Output/tags/taga/index.html")
        #expect(try tagDetails.readAsString().contains("tagA"))
    }
}
