// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "IRIKit",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "IRIKit",
            targets: ["IRIKit"]
        ),
    ],
    targets: [
        .target(
            name: "IRIKit",
        ),
        .testTarget(
            name: "IRIKitTests",
            dependencies: [
                "IRIKit"
            ],
            resources: [
                .copy("Resources/NormalizationTest-3.2.0.txt"),
                .copy("Resources/NormalizationTest-17.0.0.txt"),
            ]
        ),
    ]
)
