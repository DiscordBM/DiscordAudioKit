# Getting Started with Dave

Add DAVE end-to-end encryption to your Swift Discord voice integration.

## Overview

Discord voice channels require the DAVE protocol for end-to-end encryption. The `Dave` module provides ``DaveSession``, a Swift 6 actor that manages MLS group keys, protocol transitions, and AES-128-GCM frame encryption.

## Adding the Dependency

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/DiscordBM/DiscordAudioKit.git", from: "0.1.0")
]
```

Add `DiscordAudioKit` (or `Dave`) to your target:

```swift
.target(
    name: "MyVoiceClient",
    dependencies: [
        .product(name: "DiscordAudioKit", package: "DiscordAudioKit")
    ]
)
```

## Basic Usage

### 1. Initialize a Session

Create a ``DaveSession`` with your bot or user ID and the target voice channel ID:

```swift
import DiscordAudioKit

let session = try DaveSession(
    userID: 123456789012345678,
    channelID: 987654321098765432
)
```

### 2. Monitor Outgoing Messages

Forward messages emitted on `session.outgoing` over the Discord Voice Gateway:

```swift
Task {
    for await message in await session.outgoing {
        switch message {
        case .keyPackage(let data):
            // send Opcode 26 (Key Package)
            break
        case .commitAndWelcome(let data):
            // send Opcode 28 (Commit + Welcome)
            break
        case .readyForTransition(let transitionID):
            // send Opcode 23 (Ready for Transition)
            break
        case .invalidCommitWelcome(let transitionID):
            // send Opcode 31 (Invalid Commit/Welcome)
            break
        }
    }
}
```

### 3. Encrypting Audio Frames

Map your outgoing RTP SSRC to Opus codec, verify ``DaveSession/isReady``, and encrypt outbound frames:

```swift
try await session.assignSSRC(1001, codec: .opus)

// never send unencrypted frames when the session is not ready (the hold rule)
guard await session.isReady else {
    return
}

let ciphertext = try await session.encrypt(frame: opusPacket.bytes, ssrc: 1001)
// send ciphertext over voice UDP socket
```

### 4. Decrypting Remote Audio Frames

When receiving encrypted audio packets from remote members:

```swift
let plaintext = try await session.decrypt(
    frame: receivedPacket,
    userID: remoteSenderUserID
)
// feed plaintext to OpusDecoder from DiscordAudioKit
```
