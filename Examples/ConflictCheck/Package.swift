// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ConflictCheck",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(name: "DiscordAudioKit", path: "../.."),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "5.1.1"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.37.6"),
    ],
    targets: [
        .executableTarget(
            name: "ConflictCheck",
            dependencies: [
                .product(name: "Dave", package: "DiscordAudioKit"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
            ]
        )
    ]
)
