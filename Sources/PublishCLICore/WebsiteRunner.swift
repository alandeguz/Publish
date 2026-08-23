/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Files
import ShellOut

internal struct WebsiteRunner {
    let folder: Folder
    var portNumber: Int

    func run() throws {
        let generator = WebsiteGenerator(folder: folder)
        try generator.generate()

        let outputFolder = try resolveOutputFolder()

        let serverQueue = DispatchQueue(label: "Publish.WebServer")
        let serverProcess = Process()
        let portNumber = portNumber
        let outputPath = outputFolder.path

        print("""
        🌍 Starting web server at http://localhost:\(portNumber)

        Press ENTER to stop the server and exit
        """)

        serverQueue.async {
            do {
                _ = try shellOut(
                    to: "python3 -m http.server \(portNumber)",
                    at: outputPath,
                    process: serverProcess
                )
            } catch let error as ShellOutError {
                WebsiteRunner.outputServerErrorMessage(
                    error.message,
                    portNumber: portNumber
                )
            } catch {
                WebsiteRunner.outputServerErrorMessage(
                    error.localizedDescription,
                    portNumber: portNumber
                )
            }

            serverProcess.terminate()
            exit(1)
        }

        _ = readLine()
        serverProcess.terminate()
    }
}

private extension WebsiteRunner {
    func resolveOutputFolder() throws -> Folder {
        do { return try folder.subfolder(named: "Output") }
        catch { throw CLIError.outputFolderNotFound }
    }

    static func outputServerErrorMessage(
        _ message: String,
        portNumber: Int
    ) {
        var message = message

        if message.hasPrefix("Traceback"),
           message.contains("Address already in use") {
            message = """
            A localhost server is already running on port number \(portNumber).
            - Perhaps another 'publish run' session is running?
            - Publish uses Python's simple HTTP server, so to find any
              running processes, you can use either Activity Monitor
              or the 'ps' command and search for 'python'. You can then
              terminate any previous process in order to start a new one.
            """
        }

        fputs("\n❌ Failed to start local web server:\n\(message)\n", stderr)
    }
}
