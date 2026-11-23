# ``Audio``

Audio decoding and 20ms Opus frame streaming in DiscordAudioKit.

## Overview

The `Audio` module decodes audio files (MP3, WAV, FLAC) into 48kHz stereo float PCM and packages them into the 20ms Opus packets required by Discord voice channels.

In DiscordAudioKit, `Audio` feeds encoded ``OpusPacket`` instances directly into `DaveSession` for end-to-end encryption before UDP transmission.

### Pipeline Stages

1. **Decode**: ``AudioDecoder`` decodes audio from files, memory buffers, or byte streams, resampling to 48kHz stereo float PCM.
2. **Chunk**: ``FrameChunker`` slices PCM samples into 960-sample (20ms) chunks, padding trailing partial frames with silence.
3. **Encode**: ``OpusEncoder`` compresses each 20ms frame into an ``OpusPacket``.
4. **Stream**: ``OpusPacketStream`` orchestrates pull-based streaming via `AsyncSequence` or synchronous `next()`.

## Topics

### Guides

- <doc:GettingStarted>
- <doc:Pipeline>

### Decoding

- ``AudioDecoder``
- ``AudioInput``
- ``AudioFileInfo``

### Opus Codec

- ``OpusEncoder``
- ``OpusDecoder``
- ``OpusPacket``
- ``OpusConfiguration``

### Streaming Pipeline

- ``FrameChunker``
- ``OpusPacketStream``

### Constants and Errors

- ``AudioConstants``
- ``AudioError``
