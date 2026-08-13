/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Testing
import PublishCLICore
import Files
import ShellOut

final class CLITests: PublishTestCase {
    @Test func `Website Project Generation`() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary()
        try makeCLI(in: folder, command: "new").run(in: folder)
        try makeCLI(in: folder, command: "generate").run(in: folder)
        #endif
    }

    @Test func `Plugin Project Generation`() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "Name")
        try makeCLI(in: folder, command: "new", "plugin").run(in: folder)

        #expect(folder.containsFile(at: "Sources/Name/Name.swift"))
        #expect((try folder.getPackageName()) == ("Name"))

        // Make sure that the project can build
        try shellOut(to: "swift build", at: folder.path)
        #endif
    }

    @Test func `Site Name`() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "Name")
        try makeCLI(in: folder, command: "new").run(in: folder)
        #expect((try folder.getPackageName()) == ("Name"))
        #endif
    }
    
    @Test func `Site Name From Lowercased Folder Name`() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "name")
        try makeCLI(in: folder, command: "new").run(in: folder)
        #expect((try folder.getPackageName()) == ("Name"))
        #endif
    }
    
    @Test func `Site Name From Folder Name Starting With Digit`() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "1-name")
        try makeCLI(in: folder, command: "new").run(in: folder)
        #expect((try folder.getPackageName()) == ("Name"))
        #endif
    }
    
    @Test func `Site Name From Camel Case Folder Name`() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "CamelCaseName")
        try makeCLI(in: folder, command: "new").run(in: folder)
        #expect((try folder.getPackageName()) == ("CamelCaseName"))
        #endif
    }

    @Test func `Site Name With Non Letter Valid Characters Folder Name`() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "Blog.CamelCaseName2.com")
        try makeCLI(in: folder, command: "new").run(in: folder)
        #expect((try folder.getPackageName()) == ("BlogCamelCaseName2Com"))
        #endif
    }
    
    @Test func `Site Name From Folder Name With Non Letters`() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "My website 1")
        try makeCLI(in: folder, command: "new").run(in: folder)
        #expect((try folder.getPackageName()) == ("MyWebsite"))
        #endif
    }
    
    @Test func `Site Name From Digits Only Folder Name`() throws {
        #if INCLUDE_CLI
        let folder = try Folder.createTemporary(named: "1")
        try makeCLI(in: folder, command: "new").run(in: folder)
        let name = try folder.getPackageName()
        #expect(!(name.isEmpty))
        #endif
    }
}

private extension CLITests {
    func makeCLI(in folder: Folder, command: String...) throws -> CLI {
        let thisFile = try File(path: "\(#file)")
        let pathSuffix = "/Tests/PublishTests/Tests/CLITests.swift"

        let repositoryFolder = try Folder(
            path: String(thisFile.path.dropLast(pathSuffix.count))
        )

        return CLI(
            arguments: [folder.path] + command,
            publishRepositoryURL: URL(
                fileURLWithPath: repositoryFolder.path
            ),
            publishVersion: "0.1.0"
        )
    }
}

private extension Folder {
    static func createTemporary(named: String) throws -> Self {
        let folder = try Folder.createTemporary()
        return try folder.createSubfolder(named: named)
    }
    
    func getPackageName() throws -> String {
        let sourcesFolder = try subfolder(named: "Sources")
        return try #require(sourcesFolder.subfolders.first?.name)
    }
}
