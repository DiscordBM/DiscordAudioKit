# Getting Started with Audio

Decode audio files and stream 20ms Opus packets for Discord voice.

## Overview

Discord voice channels require 48kHz stereo Opus packets with a 20ms duration (960 samples per channel). The `Audio` module provides an end-to-end pipeline that transforms MP3, WAV, or FLAC files into 20ms Opus frames ready for transmission.

## Adding the Dependency

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/DiscordBM/DiscordAudioKit.git", from: "0.1.0")
]
```

Add `DiscordAudioKit` (or `Audio`) to your target:

```swift
.target(
    name: "MyVoiceBot",
    dependencies: [
        .product(name: "DiscordAudioKit", package: "DiscordAudioKit")
    ]
)
```

## Basic Usage

### Streaming Packets Asynchronously

Use ``OpusPacketStream`` with Swift's async sequence syntax:

```swift
import DiscordAudioKit

let decoder = try AudioDecoder(path: "track.mp3")
let stream = try OpusPacketStream(decoder, configuration: .music)

for try await packet in stream {
    // encrypt with DaveSession and send over voice UDP socket:
    // let encrypted = try await session.encrypt(frame: packet.bytes, ssrc: ssrc)
}
```

### Pulling Packets on a Timer Clock

When your voice framework drives playback on a 20ms timer tick:

```swift
import DiscordAudioKit

let decoder = try AudioDecoder(path: "track.wav")
let stream = try OpusPacketStream(decoder, configuration: .music)

// on each 20ms timer tick:
if let packet = try stream.next() {
    send(packet.bytes)
} else {
    // playback finished
}
```
