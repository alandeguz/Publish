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

class PublishTestCase {
    @discardableResult
    func publishWebsite(
        in folder: Folder? = nil,
        using steps: [PublishingStep<WebsiteStub.WithoutItemMetadata>],
        content: [Path : String] = [:],
        deploy: Bool? = nil
    ) async throws -> PublishedWebsite<WebsiteStub.WithoutItemMetadata> {
        try await performWebsitePublishing(
            in: folder,
            using: steps,
            files: content,
            filePathPrefix: "Content/",
            deploy: deploy
        )
    }

    func publishWebsite(
        _ site: WebsiteStub.WithoutItemMetadata = .init(),
        in folder: Folder? = nil,
        using theme: Theme<WebsiteStub.WithoutItemMetadata>,
        content: [Path : String] = [:],
        additionalSteps: [PublishingStep<WebsiteStub.WithoutItemMetadata>] = [],
        plugins: [Plugin<WebsiteStub.WithoutItemMetadata>] = [],
        expectedHTML: [Path : String],
        allowWhitelistedOutputFiles: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let folder = try folder ?? Folder.createTemporary()

        let contentFolderName = "Content"
        try? folder.subfolder(named: contentFolderName).delete()

        let contentFolder = try folder.createSubfolder(named: contentFolderName)
        try addFiles(withContent: content, to: contentFolder, pathPrefix: "")

        try await site.publish(
            withTheme: theme,
            at: Path(folder.path),
            rssFeedSections: [],
            additionalSteps: additionalSteps,
            plugins: plugins
        )

        try verifyOutput(
            in: folder,
            expectedHTML: expectedHTML,
            allowWhitelistedFiles: allowWhitelistedOutputFiles,
            file: file,
            line: line
        )
    }

    func publishWebsiteWithPodcast(
        in folder: Folder? = nil,
        using steps: [PublishingStep<WebsiteStub.WithPodcastMetadata>],
        content: [Path : String] = [:],
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        try await performWebsitePublishing(
            in: folder,
            using: steps,
            files: content,
            filePathPrefix: "Content/"
        )
    }

    func verifyOutput(in folder: Folder,
                      expectedHTML: [Path : String],
                      allowWhitelistedFiles: Bool = true,
                      file: StaticString = #filePath,
                      line: UInt = #line) throws {
        let outputFolder = try folder.subfolder(named: "Output")

        let whitelistedPaths: Set<Path> = [
            "index.html",
            "one/index.html",
            "two/index.html",
            "three/index.html",
            "custom-raw-value/index.html",
            "tags/index.html"
        ]

        var expectedHTML = expectedHTML.mapValues { html in
            HTML(.body(.raw(html))).render()
        }

        for outputFile in outputFolder.files.recursive where outputFile.extension == "html" {
            let relativePath = Path(outputFile.path(relativeTo: outputFolder))

            guard let html = expectedHTML.removeValue(forKey: relativePath) else {
                guard allowWhitelistedFiles,
                      whitelistedPaths.contains(relativePath) else {
                    Issue.record("Unexpected output file: \(relativePath)")
                    return
                }

                continue
            }

            let outputHTML = try outputFile.readAsString()

            #expect(outputHTML == html, "HTML mismatch. '\(outputHTML)' is not equal to '\(html)'.")
        }

        let missingPaths = expectedHTML.keys.map { $0.string }

        #expect(
            missingPaths.isEmpty,
            "Missing output files: \(missingPaths.joined(separator: ", "))"
        )
    }

    @discardableResult
    func publishWebsite<T: WebsiteItemMetadata>(
        withItemMetadataType itemMetadataType: T.Type,
        using steps: [PublishingStep<WebsiteStub.WithItemMetadata<T>>],
        content: [Path : String] = [:]
    ) async throws -> PublishedWebsite<WebsiteStub.WithItemMetadata<T>> {
        try await performWebsitePublishing(
            using: steps,
            files: content,
            filePathPrefix: "Content/"
        )
    }

    func generateItem(
        in section: WebsiteStub.SectionID = .one,
        fromMarkdown markdown: String,
        fileName: String = "markdown.md"
    ) async throws -> Item<WebsiteStub.WithoutItemMetadata> {
        let site = try await publishWebsite(
            using: [
                .addMarkdownFiles()
            ],
            content: [
                "\(section.rawValue)/\(fileName)" : markdown
            ]
        )

        return try #require(site.sections[section].items.first)
    }

    func generateItem<T: WebsiteItemMetadata>(
        withMetadataType metadataType: T.Type,
        in section: WebsiteStub.SectionID = .one,
        fromMarkdown markdown: String,
        fileName: String = "markdown.md"
    ) async throws -> Item<WebsiteStub.WithItemMetadata<T>> {
        let site = try await publishWebsite(
            withItemMetadataType: T.self,
            using: [
                .addMarkdownFiles()
            ],
            content: [
                "\(section.rawValue)/\(fileName)" : markdown
            ]
        )

        return try #require(site.sections[section].items.first)
    }
}

private extension PublishTestCase {
    func addFiles(withContent fileContent: [Path : String],
                  to folder: Folder,
                  pathPrefix: String) throws {
        for (path, content) in fileContent {
            let path = pathPrefix + path.string
            try folder.createFile(at: path).write(content)
        }
    }

    @discardableResult
    func performWebsitePublishing<T: WebsiteStub>(
        in folder: Folder? = nil,
        using steps: [PublishingStep<T>],
        files: [Path : String],
        filePathPrefix: String = "",
        deploy: Bool? = nil
    ) async throws -> PublishedWebsite<T> {
        let folder = try folder ?? Folder.createTemporary()

        try addFiles(withContent: files, to: folder, pathPrefix: filePathPrefix)

        return try await T().publish(
            at: Path(folder.path),
            using: steps,
            deploy: deploy
        )
    }
}
