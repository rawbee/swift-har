// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "HAR",
    platforms: [
        .macOS(.v10_15),
        .tvOS(.v13),
        .iOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "HAR",
            targets: ["HAR"]),
    ],
    targets: [
        .target(name: "HAR"),
        .testTarget(
            name: "HARTests",
            dependencies: ["HAR"]),
    ])
