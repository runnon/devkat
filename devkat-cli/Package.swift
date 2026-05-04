// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "devkat-cli",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "DevKatParser",
            path: "Sources/DevKatParser"
        ),
        .executableTarget(
            name: "devkat-push",
            dependencies: ["DevKatParser"],
            path: "Sources/devkat-push"
        ),
        .testTarget(
            name: "DevKatParserTests",
            dependencies: ["DevKatParser"],
            path: "Tests/DevKatParserTests"
        ),
    ]
)
