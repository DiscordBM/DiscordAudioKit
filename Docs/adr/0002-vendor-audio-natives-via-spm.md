# ADR 0002: Vendor libopus and miniaudio via SwiftPM C Targets

## Status

Accepted

## Context

For decoding audio files (WAV, MP3, FLAC) and encoding/decoding Opus packets (Discord voice standard 48 kHz stereo 20 ms frames), `Audio` needs:
1. `miniaudio`: A single-file C audio decoding and resampling library.
2. `libopus`: The IETF reference Opus codec implementation.

To maintain zero system dependencies and complete independence across all supported platforms (macOS arm64, Linux x86_64, Linux aarch64), both libraries are vendored into the package as Clang targets (`CMiniaudio` and `COpus`).

## Decisions

1. **`CMiniaudio` Configuration**:
   - Single compilation unit `Sources/CMiniaudio/src/miniaudio.c`.
   - Stripped of all hardware audio device I/O and sound engine overhead:
     - `MA_NO_DEVICE_IO`
     - `MA_NO_THREADING`
     - `MA_NO_ENCODING`
     - `MA_NO_GENERATION`
     - `MA_NO_RESOURCE_MANAGER`
     - `MA_NO_NODE_GRAPH`
     - `MA_NO_ENGINE`
   - Only format decoders (WAV, MP3, FLAC) and the internal resampler/channel converter remain active.
   - Result: 100% portable C code requiring zero OS audio frameworks (no CoreAudio on Apple, no ALSA/PulseAudio on Linux).

2. **`COpus` Configuration**:
   - Vendored from official Xiph.Org `opus` tag `v1.5.2`.
   - Core sources included: `src/`, `celt/`, `silk/`, `silk/float/`.
   - Demos, command-line test utilities, and assembly optimizations requiring compiler unsafeFlags are excluded.
   - Standard compilation definitions applied:
     - `OPUS_BUILD`
     - `VAR_ARRAYS`
     - `HAVE_LRINT`, `HAVE_LRINTF`
     - `FLOAT_APPROX`
   - Public headers cleanly exposed via `Sources/COpus/include/module.modulemap`.

3. **Symbol Hygiene & Deconfliction**:
   - `CMiniaudio` defines static inline functions and internal static decoding functions, exposing only public API with `ma_` prefixes.
   - `COpus` symbols all carry the standard `opus_` / `celt_` / `silk_` prefixes.
   - AddressSanitizer and LeakSanitizer tests verify clean lifecycle without memory leaks or buffer overflows.

## Consequences

- **Pros**:
  - Pure SwiftPM builds without external dependencies or CMake.
  - Portable across macOS and Linux with zero OS audio system libraries.
  - Fast, modular compilation with clean separation between `Dave` and `Audio`.
- **Cons**:
  - Platform-specific SIMD assembly optimizations are disabled in favour of portable C to avoid non-portable SPM unsafeFlags.
