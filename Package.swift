// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocalizeXib",
    products: [
        .executable(name: "localize-xibs", targets: ["LocalizeXib"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.0.1")),
        .package(url: "https://github.com/kylef/PathKit", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "LocalizeXib",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "PathKit", package: "PathKit"),
                .product(name: "Rainbow", package: "Rainbow"),
            ]
        ),
        .testTarget(
            name: "LocalizeXibTests",
            dependencies: [.target(name: "LocalizeXib")]
        ),
    ]
)
