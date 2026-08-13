/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Testing
import Publish

final class ErrorTests: PublishTestCase {
    @Test func `Error For Invalid Root Path`() async throws {
        await assertErrorThrown(
            try await WebsiteStub.WithoutItemMetadata().publish(
                at: "🤷‍♂️",
                using: []
            ),
            PublishingError(
                path: "🤷‍♂️",
                infoMessage: "Could not find the requested root folder"
            )
        )
    }

    @Test func `Error For Missing Markdown Metadata`() async throws {
        struct Metadata: WebsiteItemMetadata {
            let string: String
        }

        let markdown = """
        ---
        title: Hello
        ---
        """

        await assertErrorThrown(
            try await generateItem(
                withMetadataType: Metadata.self,
                in: .one,
                fromMarkdown: markdown,
                fileName: "file.md"
            ),
            PublishingError(
                stepName: "Add Markdown files from 'Content' folder",
                path: "one/file.md",
                infoMessage: "Missing metadata value for key 'string'"
            )
        )
    }

    @Test func `Error For Invalid Markdown Metadata`() async throws {
        let markdown = """
        ---
        audio.url: https://[
        ---
        """

        await assertErrorThrown(
            try await generateItem(
                in: .one,
                fromMarkdown: markdown,
                fileName: "file.md"
            ),
            PublishingError(
                stepName: "Add Markdown files from 'Content' folder",
                path: "one/file.md",
                infoMessage: "Invalid metadata value for key 'audio.url'"
            )
        )
    }

    @Test func `Error For Throwing During Item Mutation`() async throws {
        struct Error: LocalizedError {
            var errorDescription: String? { "An error" }
        }

        await assertErrorThrown(
            try await publishWebsite(using: [
                .addItem(.stub(withPath: "path/to/item")),
                .mutateAllItems { _ in
                    throw Error()
                }
            ]),
            PublishingError(
                stepName: "Mutate all items",
                path: "one/path/to/item",
                infoMessage: "Item mutation failed",
                underlyingError: Error()
            )
        )
    }

    @Test func `Error For Missing Page`() async throws {
        await assertErrorThrown(
            try await publishWebsite(using: [
                .mutatePage(at: "invalid/path") { _ in }
            ]),
            PublishingError(
                stepName: "Mutate page at 'invalid/path'",
                path: "invalid/path",
                infoMessage: "Page not found"
            )
        )
    }

    @Test func `Error For Throwing During Page Mutation`() async throws {
        struct Error: LocalizedError {
            var errorDescription: String? { "An error" }
        }

        await assertErrorThrown(
            try await publishWebsite(using: [
                .addPage(.stub(withPath: "page")),
                .mutateAllPages { _ in
                    throw Error()
                }
            ]),
            PublishingError(
                stepName: "Mutate all pages",
                path: "page",
                infoMessage: "Page mutation failed",
                underlyingError: Error()
            )
        )
    }

    @Test func `Error For Missing Folder`() async throws {
        await assertErrorThrown(
            try await publishWebsite(using: [
                .copyFiles(at: "non/existing")
            ]),
            PublishingError(
                stepName: "Copy 'non/existing' files",
                path: "non/existing",
                infoMessage: "Folder not found"
            )
        )
    }

    @Test func `Error For Missing File`() async throws {
        await assertErrorThrown(
            try await publishWebsite(using: [
                .copyFile(at: "non/existing.png")
            ]),
            PublishingError(
                stepName: "Copy file 'non/existing.png'",
                path: "non/existing.png",
                infoMessage: "File not found"
            )
        )
    }

    @Test func `Error For No Publishing Steps`() async throws {
        await assertErrorThrown(
            try await publishWebsite(using: []),
            PublishingError(
                infoMessage: "WebsiteName has no generation steps."
            )
        )

    }
}
