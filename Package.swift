// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "SwiftMarkdownView",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "SwiftMarkdownView",
            targets: ["SwiftMarkdownView"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftMarkdownView",
            resources: [
              .process("Resources")
            ]
        ),
    ]
)
