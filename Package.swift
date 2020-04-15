// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "swift-har",
    products: [
        .library(
            name: "HAR",
            targets: ["HAR"]
        ),
        .library(
            name: "HARNetworking",
            targets: ["HARNetworking"]
        ),
        .library(
            name: "HARTesting",
            targets: ["HARTesting"]
        ),
    ],
    targets: [
        .target(name: "HAR"),
        .target(name: "HARNetworking", dependencies: ["HAR"]),
        .target(name: "HARTesting", dependencies: ["HAR", "HARNetworking"]),
        .testTarget(
            name: "HARTests",
            dependencies: ["HAR", "HARNetworking", "HARTesting"]
        ),
    ]
)
