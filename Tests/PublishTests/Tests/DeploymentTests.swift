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
import ShellOut

final class DeploymentTests: PublishTestCase {
    @Test func `Deployment Skipped By Default`() async throws {
        var deployed = false

        try await publishWebsite(using: [
            .step(named: "Custom") { _ in },
            .deploy(using: DeploymentMethod(name: "Deploy") { _ in
                deployed = true
            })
        ])

        #expect(!(deployed))
    }

    @Test func `Generation Steps And Plugins Skipped When Deploying`() async throws {
        var generationPerformed = false
        var pluginInstalled = false

        try await publishWebsite(using: [
            .step(named: "Skipped") { _ in
                generationPerformed = true
            },
            .installPlugin(Plugin(name: "Skipped") { _ in
                pluginInstalled = true
            }),
            .deploy(using: DeploymentMethod(name: "Deploy") { _ in })
        ], deploy: true)

        #expect(!(generationPerformed))
        #expect(!(pluginInstalled))
    }

    @Test func `Git Deployment Method`() async throws {
        let container = try Folder.createTemporary()
        let remote = try container.createSubfolder(named: "Remote.git")
        let repo = try container.createSubfolder(named: "Repo")

        try shellOut(to: [
            "git init",
            // Not all git installations init with a master branch.
            "git checkout master || git checkout -b master",
            "git config --local receive.denyCurrentBranch updateInstead"
        ], at: remote.path)

        // First generate
        try await publishWebsite(in: repo, using: [
            .generateHTML(withTheme: .foundation)
        ])

        // Then deploy
        try await publishWebsite(in: repo, using: [
            .deploy(using: .git(remote.path))
        ], deploy: true)

        let indexFile = try remote.file(named: "index.html")
        #expect(!(try indexFile.readAsString().isEmpty))
    }

	@Test func `Git Deployment Method With Error`() async throws {
        let container = try Folder.createTemporary()
        let remote = try container.createSubfolder(named: "Remote.git")
        let repo = try container.createSubfolder(named: "Repo")

        try shellOut(
          to: [
            "git init",
            // Not all git installations init with a master branch.
            "git checkout master || git checkout -b master"
          ],
          at: remote.path
        )
        
        // First generate
        try await publishWebsite(in: repo, using: [
            .generateHTML(withTheme: .foundation)
        ])

        // Then deploy
        var thrownError: PublishingError?

        do {
            try await publishWebsite(
                in: repo,
                using: [.deploy(using: .git(remote.path))],
                deploy: true
            )
        } catch {
            thrownError = error as? PublishingError
        }

        // We don't want to make too many assumptions about the way
        // Git phrases its error messages here, so we just perform
        // a few basic checks to make sure we have some form of output:
        let infoMessage = try #require(thrownError?.infoMessage)
        #expect(infoMessage.contains("receive.denyCurrentBranch"))
        #expect(infoMessage.contains("[remote rejected]"))
    }

    @Test func `Deploying Using Custom Output Folder`() async throws {
        let container = try Folder.createTemporary()

        // First generate
        try await publishWebsite(in: container, using: [
            .addMarkdownFiles(),
            .generateHTML(withTheme: .foundation)
        ], content: [
            "one/a.md": "Text"
        ])

        // Then deploy
        var outputFolder: Folder?

        try await publishWebsite(in: container, using: [
            .deploy(using: DeploymentMethod(name: "Test") { context in
                outputFolder = try context.createDeploymentFolder(
                    withPrefix: "Test",
                    outputFolderPath: "CustomOutput",
                    configure: { _ in }
                )
            })
        ], deploy: true)

        let folder = try #require(outputFolder)
        let subfolder = try folder.subfolder(named: "CustomOutput")
        #expect(subfolder.containsSubfolder(at: "one/a"))
    }
}
