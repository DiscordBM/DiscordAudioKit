# Audio Pipeline Architecture

Understand how audio frames flow through decoding, buffering, chunking, and encoding.

## Overview

The audio pipeline transforms heterogeneous input media into homogeneous 20ms Opus frames:

```
Input Source (File, Memory, or Stream)
   │
   ▼
AudioDecoder (miniaudio)
   │ Resamples and upmixes to 48kHz stereo float PCM
   ▼
FrameChunker
   │ Buffers arbitrary PCM chunks into exact 960-sample frames
   ▼
OpusEncoder (libopus)
   │ Encodes 20ms frame into compressed OpusPacket
   ▼
OpusPacketStream
   │ Yields OpusPackets on demand (AsyncSequence or next())
```

### Pull-Based Execution

Nothing is read, decoded, or encoded until the consumer requests a packet via `next()` or `for try await packet in stream`. This prevents unbounded memory growth and unnecessary CPU consumption when playback is paused or throttled.

### Trailing Frame Silence Padding

When the source audio finishes, any leftover samples in ``FrameChunker`` that do not fill an entire 20ms frame are automatically zero-padded with silence. This guarantees that every packet emitted by the pipeline contains an exact 20ms frame conforming to the Discord voice specification.

### Cancellation Handling

When the consumer task is cancelled during iteration:
- The stream immediately releases its native decoders and encoders.
- Native resources (`ma_decoder`, `opus_encoder`) are freed cleanly.
- Subsequent calls to `next()` safely throw ``AudioError/closed``.
