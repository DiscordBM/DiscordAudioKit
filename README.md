[![Swift](https://design.vapor.codes/images/swift62up.svg)](https://swift.org)
[![Documentation](https://design.vapor.codes/images/readthedocs.svg)](Docs/INTEGRATION.md)
[![Discord](https://design.vapor.codes/images/discordchat.svg)](https://discord.gg/kxfs5n7HVE)
[![Tests](https://img.shields.io/github/actions/workflow/status/DiscordBM/DiscordAudioKit/ci.yml?event=push&style=plastic&logo=github&label=tests&logoColor=%23ccc)](https://github.com/DiscordBM/DiscordAudioKit/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache_2.0-blue.svg?style=plastic)](LICENSE)

# DiscordAudioKit

The `DiscordAudioKit` module provides audio decoding, resampling, Opus encoding/decoding, and Discord DAVE E2EE voice encryption in Swift. It provides native C/C++ bindings based on the [miniaudio](https://github.com/mackron/miniaudio), [libopus](https://github.com/xiph/opus), [libdave](https://github.com/discord/libdave), [mlspp](https://github.com/cisco/mlspp), and [boringssl](https://boringssl.googlesource.com/boringssl) libraries.

All native dependencies are vendored directly in `Sources/C/` and build from source via Swift Package Manager. No external system packages (Homebrew, APT, CMake) are required.

## Getting Started

### Installing

Add `DiscordAudioKit` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/DiscordBM/DiscordAudioKit.git", from: "0.1.0"),
]
```

Add `DiscordAudioKit` to your target dependencies:

```swift
.target(
    name: "MyVoiceBot",
    dependencies: [
        .product(name: "DiscordAudioKit", package: "DiscordAudioKit"),
    ]
)
```

You can also import either module independently:
- `.product(name: "Audio", package: "DiscordAudioKit")`: Standalone audio decoding (WAV, MP3, FLAC) and Opus encoder/decoder.
- `.product(name: "Dave", package: "DiscordAudioKit")`: Standalone Discord DAVE E2EE state machine and session actor.

### Usage

#### Outbound Voice Pipeline (Decode -> Opus Encode -> DAVE Encrypt)

```swift
import DiscordAudioKit

// 1. decode audio file and stream 20ms opus frames
let decoder = try AudioDecoder(path: "song.mp3")
let packets = try OpusPacketStream(decoder, configuration: .music)

// 2. initialize DAVE E2EE session for the voice channel
let session = try DaveSession(userID: botUserID, channelID: voiceChannelID)

// 3. stream audio frames and encrypt before sending
for try await packet in packets {
    guard await session.isReady else { continue }
    let encryptedFrame = try await session.encrypt(frame: packet.bytes, ssrc: outboundSSRC)
    // send encryptedFrame over UDP voice socket
}
```

#### Pulling on a 20ms Clock

```swift
if let packet = try packets.next() {
    let encrypted = try await session.encrypt(frame: packet.bytes, ssrc: outboundSSRC)
    // send encrypted frame over UDP voice socket
}
```

#### Inbound Voice Pipeline (DAVE Decrypt -> Opus Decode)

```swift
// decrypt received UDP payload with DAVE
let decryptedFrame = try await session.decrypt(frame: receivedPayload, ssrc: inboundSSRC)

// decode opus packet back into interleaved 48kHz stereo float PCM
let pcmSamples = try opusDecoder.decode(decryptedFrame)
```

#### Standalone Audio Pipeline

```swift
import Audio

let decoder = try AudioDecoder(path: "track.flac")
let packets = try OpusPacketStream(decoder, configuration: .audio)

for try await packet in packets {
    // 20ms 48kHz stereo Opus packet (packet.bytes, packet.durationMilliseconds)
}
```

## Features

- **Audio Decoding & Resampling**: Decode WAV, MP3, and FLAC files, memory buffers, or custom byte streams via `miniaudio`. Automatically resamples to 48kHz and upmixes mono audio to stereo.
- **Opus Codec**: 20ms Discord-spec Opus packets via `libopus` with preallocated buffers and configurable bitrate, complexity, FEC, and DTX.
- **Frame Chunker**: Buffers arbitrary PCM chunks into exact 960-sample (20ms at 48kHz) stereo frames with trailing silence padding.
- **Discord DAVE E2EE**: Protocol state machine, MLS key ratchet transitions (RFC 9420), and hold rule enforcement via `libdave`.
- **Pure SwiftPM**: Zero system libraries or external build tools. Strict concurrency in Swift 6 mode with `-warnings-as-errors` enforcement.

## Building and Testing

```sh
# build with warnings as errors
$ swift build -Xswiftc -warnings-as-errors

# run all unit tests
$ swift test -Xswiftc -warnings-as-errors

# run under AddressSanitizer
$ swift test --sanitize=address -Xswiftc -warnings-as-errors

# build documentation
$ bash scripts/build-docs.bash
```

## Vendored Dependencies

All native C/C++ dependencies reside in `Sources/C/`:
- `COpus`: Xiph libopus (v1.5.2) - BSD 3-Clause
- `CMiniaudio`: Mackron miniaudio (v0.11.26) - MIT / Public Domain
- `CLibDave`: Discord libdave - Discord Proprietary / Source-available
- `CMLSPP`: Cisco MLS++ (RFC 9420) - BSD 2-Clause
- `CBoringSSL`: Google BoringSSL (C symbols prefixed with `CCryptoBoringSSL_`) - OpenSSL / ISC

## Documentation

- [Integration Guide](Docs/INTEGRATION.md): Discord voice gateway opcodes (21, 22, 24, 25, 27, 29, 30) and complete wire protocol.
- [Architecture](Docs/ARCHITECTURE.md): Memory model, zero-copy buffer flow, and concurrency design.
- [Building & Portability](Docs/BUILDING.md): Build targets and compiler requirements.
- [Testing Guide](Docs/TESTING.md): Sanitizers, audio metrics (SNR, correlation), and stress testing.
