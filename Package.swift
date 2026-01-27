// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LSJSONModel",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(name: "LSJSONModel", targets: ["LSJSONModel"])
    ],
    dependencies: [],
    targets: [
        // 主库模块
        .target(
            name: "LSJSONModel",
            path: "Sources",
            exclude: ["Docs"],
            resources: [.process("Resources")]
        ),
        // 测试模块
        .testTarget(
            name: "LSJSONModelTests",
            dependencies: ["LSJSONModel"],
            path: "Tests"
        )
    ]
)
