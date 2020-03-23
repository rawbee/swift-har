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
    ],
    targets: [
        .target(name: "HAR"),
        .target(name: "HARNetworking", dependencies: ["HAR"]),
        .testTarget(
            name: "HARTests",
            dependencies: ["HAR", "HARNetworking"]
        ),
    ]
)
