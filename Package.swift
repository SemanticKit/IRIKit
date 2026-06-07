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
    dependencies: [
        .package(url: "https://github.com/SemanticKit/ABNFKit.git", branch: "main"),
        .package(url: "https://github.com/SemanticKit/EBNFKit.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "IRIKit",
        ),
        .testTarget(
            name: "IRIKitTests",
            dependencies: [
                "IRIKit"
            ]
        ),
    ]
)
