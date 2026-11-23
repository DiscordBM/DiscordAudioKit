# Vendored Patches

List of patches applied to upstream sources.

## 0001-cboringssl-module-and-sha2.patch
- Target: `Sources/C/CBoringSSL`
- Changes:
  - Renames module map module from `CCryptoBoringSSL` to `CBoringSSL`
  - Includes `CCryptoBoringSSL_sha2.h` in `CCryptoBoringSSL.h` to expose `CCryptoBoringSSL_SHA256` to Swift
  - Provides `include/openssl/*.h` shims to redirect standard OpenSSL includes to `CCryptoBoringSSL_*.h`, with `#undef` for the 5 identifiers that clash with C++ types/enums (`SHA256`, `SHA384`, `SHA512`, `HKDF`, `X25519`).

## 0002-cmlspp-namespace.patch
- Target: `Sources/C/CMLSPP`
- Changes:
  - Adds `include/namespace.h` with `#define MLS_NAMESPACE mlspp` (matching libdave's vcpkg port)
  - Omits `mls_ds` and `mls_vectors` test/benchmark subdirectories (matching libdave's portfile)

## 0003-clibdave-private-headers.patch
- Target: `Sources/C/CLibDave`
- Changes:
  - Exposes only `dave.h` in `include/` via `module.modulemap`
  - Moves C++ internal headers to `src/dave/` to keep Swift interface pure C

## 0004-clibdave-logger-mutex.patch
- Target: `Sources/C/CLibDave`
- Changes:
  - Protects fallback `std::cout` stream logging with a `std::mutex` in `logger.cpp` to prevent data races when libdave logs concurrently from multiple threads (TSAN clean)


## 0005-cminiaudio-pure-decoder.patch
- Target: `Sources/C/CMiniaudio`
- Upstream: https://github.com/mackron/miniaudio (0.11.26)
- Changes:
  - Compiles `miniaudio.c` with `MA_NO_DEVICE_IO`, `MA_NO_THREADING`, `MA_NO_ENCODING`, `MA_NO_GENERATION`, `MA_NO_RESOURCE_MANAGER`, `MA_NO_NODE_GRAPH`, and `MA_NO_ENGINE`.
  - Excludes audio device backends (CoreAudio, ALSA, PulseAudio) to allow pure in-memory and file decoding without OS framework dependencies.

## 0006-copus-portable-c.patch
- Target: `Sources/C/COpus`
- Upstream: https://github.com/xiph/opus (v1.5.2)
- Changes:
  - Vendors core CELT, SILK, and floating-point sources.
  - Excludes standalone CLI tools, test runners, and platform assembly requiring `unsafeFlags`.
  - Builds portable float configuration with `OPUS_BUILD`, `VAR_ARRAYS`, `HAVE_LRINT`, `HAVE_LRINTF`, and `FLOAT_APPROX`.
