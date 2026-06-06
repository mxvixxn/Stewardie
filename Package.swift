// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Stewardie",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Stewardie",
            targets: ["Stewardie"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Stewardie",
            path: "Sources/Stewardie",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
