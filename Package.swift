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
                .product(name: "Ink", package: "ink"),
                .product(name: "Plot", package: "plot"),
                .product(name: "Files", package: "files"),
                .product(name: "Codextended", package: "codextended"),
                .product(name: "ShellOut", package: "shellout"),
                .product(name: "Sweep", package: "sweep"),
                .product(name: "CollectionConcurrencyKit", package: "collectionconcurrencykit")
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
