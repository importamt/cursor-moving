// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CursorMoving",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "CursorMoving", targets: ["CursorMoving"]),
    ],
    targets: [
        .target(name: "CursorMovingCore"),
        .executableTarget(name: "CursorMoving", dependencies: ["CursorMovingCore"]),
        .testTarget(name: "CursorMovingCoreTests", dependencies: ["CursorMovingCore"]),
    ]
)
