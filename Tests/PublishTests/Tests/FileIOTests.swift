/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Testing
import Publish
import Files

final class FileIOTests: PublishTestCase {
    @Test func `Copying File`() async throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(named: "File").write("Hello, world!")

        try await publishWebsite(in: folder, using: [
            .copyFile(at: "File")
        ])

        let file = try folder.file(at: "Output/File")
        #expect((try file.readAsString()) == ("Hello, world!"))
    }

    @Test func `Copying File To Specific Folder`() async throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(named: "File").write("Hello, world!")

        try await publishWebsite(in: folder, using: [
            .copyFile(at: "File", to: "Custom/Path")
        ])

        let file = try folder.file(at: "Output/Custom/Path/File")
        #expect((try file.readAsString()) == ("Hello, world!"))
    }

    @Test func `Copying Folder`() async throws {
        let folder = try Folder.createTemporary()
        try folder.createSubfolder(named: "Subfolder")

        try await publishWebsite(in: folder, using: [
            .step(named: "Copy custom folder") { context in
                try context.copyFolderToOutput(from: "Subfolder")
            }
        ])

        #expect((try? folder.subfolder(at: "Output/Subfolder")) != nil)
    }

    @Test func `Copying Resources With Folder`() async throws {
        let folder = try Folder.createTemporary()
        let resourcesFolder = try folder.createSubfolder(named: "Resources")
        try resourcesFolder.createFile(named: "File").write("Hello")
        let nestedFolder = try resourcesFolder.createSubfolder(named: "Subfolder")
        try nestedFolder.createFile(named: "Nested").write("World!")

        try await publishWebsite(in: folder, using: [
            .copyResources(includingFolder: true)
        ])

        let rootFile = try folder.file(at: "Output/Resources/File")
        let nestedFile = try folder.file(at: "Output/Resources/Subfolder/Nested")
        #expect((try rootFile.readAsString()) == ("Hello"))
        #expect((try nestedFile.readAsString()) == ("World!"))
    }

    @Test func `Copying Resources Without Folder`() async throws {
        let folder = try Folder.createTemporary()
        let resourcesFolder = try folder.createSubfolder(named: "Resources")
        try resourcesFolder.createFile(named: "File").write("Hello")
        let nestedFolder = try resourcesFolder.createSubfolder(named: "Subfolder")
        try nestedFolder.createFile(named: "Nested").write("World!")

        try await publishWebsite(in: folder, using: [
            .copyResources()
        ])

        let rootFile = try folder.file(at: "Output/File")
        let nestedFile = try folder.file(at: "Output/Subfolder/Nested")
        #expect((try rootFile.readAsString()) == ("Hello"))
        #expect((try nestedFile.readAsString()) == ("World!"))
    }

    @Test func `Creating Root Level Folder`() async throws {
        let folder = try Folder.createTemporary()

        try await publishWebsite(in: folder, using: [
            .step(named: "Create folder") { context in
                _ = try context.createFolder(at: "A")
                _ = try context.createFile(at: "B/file")
            }
        ])

        #expect((try? folder.subfolder(named: "A")) != nil)
        #expect((try? folder.file(at: "B/file")) != nil)
    }

    @Test func `Retrieving Output Folder`() async throws {
        let folder = try Folder.createTemporary()
        var firstSectionFolder: Folder?

        try await publishWebsite(in: folder, using: [
            .generateHTML(withTheme: .foundation),
            .step(named: "Get output folder") { context in
                firstSectionFolder = try context.outputFolder(at: "one")
            }
        ])

        #expect((firstSectionFolder?.name) == ("one"))
    }

    @Test func `Retrieving Output File`() async throws {
        let folder = try Folder.createTemporary()
        var itemFile: File?

        try await publishWebsite(in: folder, using: [
            .addItem(.stub(withPath: "item")),
            .generateHTML(withTheme: .foundation),
            .step(named: "Get output file") { context in
                itemFile = try context.outputFile(at: "one/item/index.html")
            }
        ])

        #expect((itemFile?.name) == ("index.html"))
    }

    @Test func `Cleaning Hidden Files In Output Folder`() async throws {
        let folder = try Folder.createTemporary()
        try folder.createFile(at: "Output/.hidden")

        try await publishWebsite(in: folder, using: [
            .step(named: "Do nothing") { _ in }
        ])

        #expect(!(folder.containsFile(named: "Output/.hidden")))
    }
}
