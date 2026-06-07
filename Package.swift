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
            name: "IRIKit"
        ),
        .testTarget(
            name: "IRIKitTests",
            dependencies: [
                "IRIKit"
            ]
        ),
    ]
)
