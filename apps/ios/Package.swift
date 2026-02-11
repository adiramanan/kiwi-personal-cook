// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Kiwi",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Kiwi", targets: ["Kiwi"])
    ],
    targets: [
        .target(
            name: "Kiwi",
            path: "Kiwi/Kiwi",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "KiwiTests",
            dependencies: ["Kiwi"],
            path: "Kiwi/KiwiTests"
        ),
        .testTarget(
            name: "KiwiUITests",
            dependencies: ["Kiwi"],
            path: "Kiwi/KiwiUITests"
        )
    ]
)
