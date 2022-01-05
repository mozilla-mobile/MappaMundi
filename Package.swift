// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MappaMundi",
    products: [
        .library(
            name: "MappaMundi",
            targets: ["MappaMundi"]),
    ],
    dependencies: [
        .package(name: "AStar", url: "https://github.com/Dev1an/A-Star", from: "3.0.0-beta-1")
    ],
    targets: [
        .target(
            name: "MappaMundi",
            dependencies: ["AStar"],
            path: "Sources")
    ]
)
