# Testing DiscordAudioKit

Testing strategy, test suites, and coverage verification for `DiscordAudioKit`.

## Overview

The test suite is built on Apple's Swift Testing framework (`import Testing`) and runs completely offline without network connections or external servers.

### Principles

- **Deterministic**: Tests do not use real-time sleeps, timers, or network sockets.
- **Fail-safe**: No forced unwraps (`!`), `try!`, or `as!` in test code; assertions use `#expect` and `try #require`.
- **Sanitizer Validated**: Every phase runs under ASAN and TSAN.
- **Audio Verification**: Frequency power verification via Goertzel filter and delay-aligned cross-correlation on Opus roundtrips.

## Test Suites

### Audio Module Suites (`Tests/AudioTests/`)

| Suite | File | Focus |
| :--- | :--- | :--- |
| **Toolchain Smoke** | `ToolchainSmokeTests.swift` | Audio constants matching Discord 48kHz 20ms specs. |
| **Native Link Spike** | `LinkTests.swift` | Direct C interop with libopus and miniaudio. |
| **Native Handle** | `NativeHandleTests.swift` | Safe ownership, idempotent close, use-after-close errors. |
| **Opus Packet** | `OpusPacketTests.swift` | TOC parsing, duration, frame counts, silence packet. |
| **Opus Encoder** | `OpusEncoderTests.swift` | 20ms PCM frame encoding, mono/stereo, bitrate, complexity. |
| **Opus Decoder** | `OpusDecoderTests.swift` | Packet decoding, loss concealment, sine correlation. |
| **Audio Decoder** | `AudioDecoderTests.swift` | In-memory WAV, MP3/FLAC fixtures, stream input, seeking. |
| **Resample & Channels** | `ResampleTests.swift` | 44.1kHz to 48kHz resampling and mono-to-stereo upmixing. |
| **Frame Chunker** | `FrameChunkerTests.swift` | Arbitrary chunk buffering, remainder carryover, silence padding. |
| **Opus Packet Stream** | `OpusPacketStreamTests.swift` | AsyncSequence pull, cancellation cleanup, synchronous clock. |
| **Readme Example** | `ReadmeExampleTests.swift` | Verifies Audio README usage example compiles and runs. |

### Dave Module Suites (`Tests/DaveTests/`)

| Suite | File | Focus |
| :--- | :--- | :--- |
| **Toolchain** | `ToolchainSmokeTests.swift` | Dave protocol version constants. |
| **BoringSSL** | `BoringSSLLinkTests.swift` | Prefixed BoringSSL link and SHA-256 test vectors. |
| **Libdave Smoke** | `LibdaveSmokeTests.swift` | C API versioning and handle create/destroy. |
| **Session FFI** | `LibdaveSessionTests.swift` | Two-party loopback using real `libdave` C API. |
| **Frames** | `LibdaveFrameTests.swift` | AES-128-GCM frame encryption, tamper resistance, passthrough. |
| **Key Ratchet** | `KeyRatchetTests.swift` | Ratchet transitions, generation gaps, nonces. |
| **Log Sink** | `LogSinkTests.swift` | Native log callback bridge thread safety. |
| **Process Exit** | `ProcessExitTests.swift` | Static destructor ordering with live native objects in subprocess. |
| **State Machine** | `SessionStateMachineTests.swift` | Table-driven state machine tests with `MockEngine`. |
| **Scenarios** | `SessionScenarioTests.swift` | Real `libdave` two-party negotiation via public `DaveSession` actor. |
| **Concurrency** | `SessionConcurrencyTests.swift` | High concurrency stress test across actors (TSAN validated). |
| **README Example** | `ReadmeExampleTests.swift` | Verifies Dave README usage example compiles and runs. |
