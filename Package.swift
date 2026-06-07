// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SemanticKit",
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
        .package(url: "https://github.com/SemanticKit/ABNFKit.git", from: "main"),
        .package(url: "https://github.com/SemanticKit/EBNFKit.git", from: "main"),
    ],
    targets: [
        .target(
            name: "IRIKit",
            exclude: [
                "Documentation",
                "README.md",
            ]
        ),
        .testTarget(
            name: "IRIKitTests",
            dependencies: [
                "IRIKit"
            ]
        ),
    ]
)
