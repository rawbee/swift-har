// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "HAR",
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
