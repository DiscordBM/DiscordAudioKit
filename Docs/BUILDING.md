# Building DiscordAudioKit

Instructions for building, testing, formatting, and generating documentation for `DiscordAudioKit`.

## Prerequisites

- **Swift**: 6.2 or higher.
- **macOS**: macOS 13 (Ventura) or higher with Xcode Command Line Tools.
- **Linux**: Ubuntu 22.04+ with official Swift toolchain.
- No external package managers (Homebrew, CMake, vcpkg) are required. All C/C++ native dependencies are vendored.

## Building the Package

### Standard Debug Build

```bash
swift build
```

### Strict Build with Warnings as Errors

The project adheres to a strict zero-warning policy:

```bash
swift build -Xswiftc -warnings-as-errors
```

### Running Tests

Run the full test suite across both `DaveTests` and `AudioTests`:

```bash
swift test -Xswiftc -warnings-as-errors
```

Filter for a specific module or test suite:

```bash
# test audio module only
swift test --filter AudioTests

# test dave module only
swift test --filter DaveTests
```

## Sanitizer Builds

Sanitizers verify memory safety and concurrency invariants:

### Address Sanitizer (ASAN)

Checks for memory leaks, buffer overflows, and use-after-free bugs across C/C++ and Swift:

```bash
swift test --sanitize=address -Xswiftc -warnings-as-errors
```

### Thread Sanitizer (TSAN)

Checks for data races across async tasks and actors:

```bash
swift test --sanitize=thread -Xswiftc -warnings-as-errors
```

## Documentation Generation

Build DocC documentation archives for both `Dave` and `Audio`:

```bash
bash scripts/build-docs.bash
```

## Formatting and Linting

```bash
# format swift sources
bash scripts/format.bash

# lint swift sources
bash scripts/lint.bash

# check for banned anti-patterns
bash scripts/check-banned.bash
```
