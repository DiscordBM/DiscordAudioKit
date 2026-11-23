// swift-tools-version: 6.2

import Foundation
import PackageDescription

let package = Package(
    name: "DiscordAudioKit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(name: "Dave", targets: ["Dave"]),
        .library(name: "Audio", targets: ["Audio"]),
        .library(name: "DiscordAudioKit", targets: ["Dave", "Audio"]),
    ],
    targets: [
        .target(
            name: "CBoringSSL",
            path: "Sources/C/CBoringSSL",
            exclude: [
                "CMakeLists.txt",
                "hash.txt",
                "PrivacyInfo.xcprivacy",
                // networking files not needed (safe to exclude on all platforms)
                "crypto/bio/connect.cc",
                "crypto/bio/socket_helper.cc",
                "crypto/bio/socket.cc",
            ],
            publicHeadersPath: "include",
            cSettings: [
                .define("_HAS_EXCEPTIONS", to: "0", .when(platforms: [.windows])),
                .define("WIN32_LEAN_AND_MEAN", .when(platforms: [.windows])),
                .define("NOMINMAX", .when(platforms: [.windows])),
            ],
            cxxSettings: []
        ),

        .target(
            name: "CMLSPP",
            dependencies: ["CBoringSSL"],
            path: "Sources/C/CMLSPP",
            publicHeadersPath: "include",
            cxxSettings: [
                .define("WITH_BORINGSSL"),
                .define("DISABLE_GREASE"),
                .define("MLS_NAMESPACE", to: "mlspp"),
                // find our openssl/ shims (rooted at CBoringSSL's public include)
                .headerSearchPath("include"),
                // private headers within src subdirectories
                .headerSearchPath("src/mls"),
                .headerSearchPath("src/hpke"),
            ]
        ),

        .target(
            name: "CLibDave",
            dependencies: ["CMLSPP"],
            path: "Sources/C/CLibDave",
            publicHeadersPath: "include",
            cxxSettings: [
                .define("DAVE_STATIC"),
                .define("WITH_BORINGSSL"),
                // libdave includes its own src/ headers via relative paths
                .headerSearchPath("src"),
            ]
        ),

        .target(
            name: "Dave",
            dependencies: ["CLibDave"],
            path: "Sources/Dave",
            swiftSettings: swiftSettings
        ),

        .target(
            name: "CDaveTestSupport",
            dependencies: [
                "CLibDave",
                "CMLSPP",
                "CBoringSSL",
            ],
            path: "Sources/C/CDaveTestSupport",
            publicHeadersPath: "include",
            cxxSettings: [
                .define("DAVE_STATIC"),
                .define("WITH_BORINGSSL"),
                .headerSearchPath("src"),
                .headerSearchPath("../CLibDave/src"),
                .headerSearchPath("../CMLSPP/include"),
                .headerSearchPath("../CBoringSSL/include"),
            ]
        ),

        .testTarget(
            name: "DaveTests",
            dependencies: [
                "Dave",
                "CLibDave",
                "CBoringSSL",
                "CDaveTestSupport",
            ],
            path: "Tests/DaveTests",
            swiftSettings: swiftSettings
        ),

        .testTarget(
            name: "DaveIntegrationTests",
            dependencies: [
                "Dave",
            ],
            path: "Tests/DaveIntegrationTests",
            swiftSettings: swiftSettings
        ),

        .target(
            name: "COpus",
            path: "Sources/C/COpus",
            publicHeadersPath: "include",
            cSettings: [
                .define("OPUS_BUILD"),
                .define("VAR_ARRAYS"),
                .define("HAVE_LRINT"),
                .define("HAVE_LRINTF"),
                .define("FLOAT_APPROX"),
                .headerSearchPath("include"),
                .headerSearchPath("src"),
                .headerSearchPath("celt"),
                .headerSearchPath("silk"),
                .headerSearchPath("silk/float"),
            ]
        ),

        .target(
            name: "CMiniaudio",
            path: "Sources/C/CMiniaudio",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
            ]
        ),

        .target(
            name: "Audio",
            dependencies: [
                "COpus",
                "CMiniaudio",
            ],
            path: "Sources/Audio",
            swiftSettings: swiftSettings
        ),

        .testTarget(
            name: "AudioTests",
            dependencies: [
                "Audio",
                "COpus",
                "CMiniaudio",
            ],
            path: "Tests/AudioTests",
            resources: [
                .copy("Fixtures"),
            ],
            swiftSettings: swiftSettings
        ),
    ],
    cxxLanguageStandard: .cxx17
)

private let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

if ProcessInfo.processInfo.environment["BMAUDIOKIT_DOCS"] == "1" || ProcessInfo.processInfo.environment["AUDIO_DOCS"] == "1" {
    package.dependencies.append(
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.3")
    )
}
