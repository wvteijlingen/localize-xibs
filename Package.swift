// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocalizeXib",
    products: [
        .executable(name: "localize-xibs", targets: ["LocalizeXibCli"]),
        .library(name: "LocalizeXibCore", targets: ["LocalizeXibCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.0.1")),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "LocalizeXibCore",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Rainbow",
            ]
        ),
        .target(
            name: "LocalizeXibCli",
            dependencies: ["LocalizeXibCore"]
        ),
        .testTarget(
            name: "LocalizeXibTests",
            dependencies: ["LocalizeXibCore", "Rainbow"]
        ),
    ]
)
