// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZenBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ZenBar", targets: ["ZenBarApp"])
    ],
    targets: [
        .executableTarget(
            name: "ZenBarApp"
        ),
        .testTarget(
            name: "ZenBarTests",
            dependencies: ["ZenBarApp"]
        )
    ]
)
