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
            from: "0.6.2"
        ),
        .package(
            url: "https://github.com/alandeguz/plot.git",
            from: "0.15.0"
        ),
        .package(
            url: "https://github.com/alandeguz/files.git",
            from: "4.4.0"
        ),
        .package(
            url: "https://github.com/alandeguz/codextended.git",
            from: "0.4.0"
        ),
        .package(
            url: "https://github.com/alandeguz/shellout.git",
            from: "2.4.0"
        ),
        .package(
            url: "https://github.com/alandeguz/sweep.git",
            from: "0.6.0"
        ),
        .package(
            url: "https://github.com/alandeguz/collectionConcurrencyKit.git",
            from: "0.2.0"
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
