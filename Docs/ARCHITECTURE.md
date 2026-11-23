# Architecture

DiscordAudioKit provides the audio pipeline and end-to-end encryption needed for Discord voice in Swift.

## Pipeline Architecture

```
                 Input Source (File, Buffer, or Stream)
                                   │
                                   ▼
                 ┌───────────────────────────────────┐
                 │       AudioDecoder (miniaudio)    │
                 │   Resample to 48kHz, mono/stereo  │
                 └─────────────────┬─────────────────┘
                                   │ Float PCM
                                   ▼
                 ┌───────────────────────────────────┐
                 │           FrameChunker            │
                 │    Pads/chunks to 960 samples     │
                 └─────────────────┬─────────────────┘
                                   │ 20ms Frame
                                   ▼
                 ┌───────────────────────────────────┐
                 │       OpusEncoder (libopus)       │
                 │    Encodes to 20ms OpusPacket     │
                 └─────────────────┬─────────────────┘
                                   │ Opus Bytes
                                   ▼
                 ┌───────────────────────────────────┐
                 │       DaveSession (libdave)       │
                 │    AES-128-GCM frame encryption   │
                 └─────────────────┬─────────────────┘
                                   │ Encrypted Frame
                                   ▼
                 ┌───────────────────────────────────┐
                 │     RTP Transport & UDP Socket    │
                 └───────────────────────────────────┘
```

## Module Structure

1. **`Audio` Module (`Sources/Audio/`)**:
   - `AudioDecoder`: Heap-allocated `ma_decoder` wrapped in Swift. Handles format decoding and resampling to 48kHz stereo.
   - `FrameChunker`: Sendable buffer collecting arbitrary sample counts into exact 20ms frames, padding remainders with silence.
   - `OpusEncoder` / `OpusDecoder`: libopus wrappers with explicit channel and configuration validation.
   - `OpusPacketStream`: Pull-based async sequence and synchronous clock iterator.

2. **`Dave` Module (`Sources/Dave/`)**:
   - `DaveSession`: Swift 6 actor maintaining MLS session state, transition bookkeeping, and outbound key packages.
   - `LibdaveSession` / `LibdaveEncryptor` / `LibdaveDecryptor`: C++ FFI bridges over `libdave`.
   - `KeyRatchet`: Tracks key generation progression for outbound and inbound media streams.

3. **Native Sources (`Sources/C/`)**:
   - `CBoringSSL`: BoringSSL with `CCryptoBoringSSL_` prefixing to avoid symbol collisions with `swift-crypto` or `swift-nio-ssl`.
   - `CMLSPP`: Cisco MLS C++ implementation without GREASE.
   - `CLibDave`: Discord voice E2EE implementation.
   - `COpus`: Xiph libopus float build.
   - `CMiniaudio`: Mackron miniaudio stripped of unused subsystems (audio playback engine, device I/O).

## Memory and Ownership Rules

- **Native Handles**: Pointer-owning classes wrap C allocations using `NativeHandle<T>` with RAII deallocation on `deinit` and idempotent `close()`.
- **Single-Owner Wrappers**: Native wrappers are not `Sendable` because underlying C/C++ libraries are not thread-safe. They are owned by one actor or task at a time.
- **Value Types**: Data packets (`OpusPacket`), configurations, and info types are value types conforming to `Sendable`.
