/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing
import Publish
import Plot
import Ink

final class PluginTests: PublishTestCase {
    @Test func `Adding Content Using Plugin`() async throws {
        let site = try await publishWebsite(using: [
            .installPlugin(Plugin(name: "Plugin") { context in
                context.addItem(.stub())
            })
        ])

        #expect((site.sections[.one].items.count) == (1))
    }

    @Test func `Adding Ink Modifier Using Plugin`() async throws {
        let site = try await publishWebsite(using: [
            .installPlugin(Plugin(name: "Plugin") { context in
                context.markdownParser.addModifier(Modifier(
                    target: .paragraphs,
                    closure: { html, _ in
                        "<div>\(html)</div>"
                    }
                ))
            }),
            .addMarkdownFiles()
        ], content: [
            "one/a.md": "Hello"
        ])

        let items = site.sections[.one].items
        #expect((items.count) == (1))
        #expect((items.first?.path) == ("one/a"))
        #expect((items.first?.body.html) == ("<div><p>Hello</p></div>"))
    }

    @Test func `Adding Plugin To Default Pipeline`() async throws {
        let htmlFactory = HTMLFactoryMock<WebsiteStub.WithoutItemMetadata>()
        htmlFactory.makeIndexHTML = { content, _ in
            HTML(.body(content.body.node))
        }

        try await publishWebsite(
            using: Theme(htmlFactory: htmlFactory),
            content: ["index.md": "Hello, World!"],
            plugins: [Plugin(name: "Plugin") { context in
                context.markdownParser.addModifier(Modifier(
                    target: .paragraphs,
                    closure: { html, _ in
                        "<section>\(html)</section>"
                    }
                ))
            }],
            expectedHTML: ["index.html": "<section><p>Hello, World!</p></section>"]
        )
    }
}
