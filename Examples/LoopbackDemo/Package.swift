// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "LoopbackDemo",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    dependencies: [
        .package(name: "DiscordAudioKit", path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "LoopbackDemo",
            dependencies: [
                .product(name: "Dave", package: "DiscordAudioKit")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
