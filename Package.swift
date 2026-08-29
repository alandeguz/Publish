// swift-tools-version:6.2

/**
*  Publish
*  Copyright (c) Alan DeGuzman 2026
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import PackageDescription

let package = Package(
    name: "Publish",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "Publish", targets: ["Publish"]),
        .executable(name: "publish-cli", targets: ["PublishCLI"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/alandeguz/ink.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/alandeguz/plot.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/alandeguz/files.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/alandeguz/codextended.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/alandeguz/shellout.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/alandeguz/sweep.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/alandeguz/collectionConcurrencyKit.git",
            branch: "main"
        )
    ],
    targets: [
        .target(
            name: "Publish",
            dependencies: [
                .product(name: "Ink", package: "Ink"),
                .product(name: "Plot", package: "Plot"),
                .product(name: "Files", package: "Files"),
                .product(name: "Codextended", package: "Codextended"),
                .product(name: "ShellOut", package: "ShellOut"),
                .product(name: "Sweep", package: "Sweep"),
                .product(name: "CollectionConcurrencyKit", package: "CollectionConcurrencyKit")
            ]
        ),
        .executableTarget(
            name: "PublishCLI",
            dependencies: ["PublishCLICore"]
        ),
        .target(
            name: "PublishCLICore",
            dependencies: ["Publish"]
        ),
        .testTarget(
            name: "PublishTests",
            dependencies: ["Publish", "PublishCLICore"]
        )
    ]
)
