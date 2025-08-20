// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TimerApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TimerApp", targets: ["TimerApp"]),
        .executable(name: "LaunchAtLoginHelper", targets: ["LaunchAtLoginHelper"])
    ],
    dependencies: [
        // No external dependencies - using only system frameworks
    ],
    targets: [
        .executableTarget(
            name: "TimerApp",
            dependencies: [],
            path: "TimerApp/Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "LaunchAtLoginHelper",
            dependencies: [],
            path: "LaunchAtLoginHelper"
        ),
        .testTarget(
            name: "TimerAppTests",
            dependencies: ["TimerApp"],
            path: "TimerApp/Tests"
        )
    ]
)
