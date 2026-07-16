// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "SnapSail",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "SnapSailCore", targets: ["SnapSailCore"]),
        .executable(name: "SnapSail", targets: ["SnapSail"])
    ],
    targets: [
        .target(name: "SnapSailCore"),
        .executableTarget(
            name: "SnapSail",
            dependencies: ["SnapSailCore"]
        ),
        .testTarget(
            name: "SnapSailCoreTests",
            dependencies: ["SnapSailCore"]
        )
    ]
)
