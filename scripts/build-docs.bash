#!/usr/bin/env bash
set -euo pipefail

echo "=== building docc documentation ==="

DOCS_DIR="${PWD}/.build/docs"
SYMBOL_GRAPH_DIR="${PWD}/.build/symbol-graphs"
rm -rf "$DOCS_DIR" "$SYMBOL_GRAPH_DIR"
mkdir -p "$DOCS_DIR" "$SYMBOL_GRAPH_DIR"

echo "--- extracting symbol graphs ---"
touch Sources/Dave/Dave.swift
touch Sources/Audio/AudioError.swift
swift build -Xswiftc -emit-symbol-graph -Xswiftc -emit-symbol-graph-dir -Xswiftc "$SYMBOL_GRAPH_DIR"

mkdir -p "$SYMBOL_GRAPH_DIR/Dave" "$SYMBOL_GRAPH_DIR/Audio"
if [ -f "$SYMBOL_GRAPH_DIR/Dave.symbols.json" ]; then
    cp "$SYMBOL_GRAPH_DIR/Dave.symbols.json" "$SYMBOL_GRAPH_DIR/Dave/"
fi
if [ -f "$SYMBOL_GRAPH_DIR/Audio.symbols.json" ]; then
    cp "$SYMBOL_GRAPH_DIR/Audio.symbols.json" "$SYMBOL_GRAPH_DIR/Audio/"
fi

DOCC_BIN=""
if command -v xcrun >/dev/null 2>&1; then
    DOCC_BIN="$(xcrun --find docc 2>/dev/null || true)"
fi
if [ -z "$DOCC_BIN" ] && command -v docc >/dev/null 2>&1; then
    DOCC_BIN="$(command -v docc)"
fi

if [ -n "$DOCC_BIN" ]; then
    echo "--- compiling Dave docc archive ---"
    "$DOCC_BIN" convert Sources/Dave/Documentation.docc \
        --additional-symbol-graph-dir "$SYMBOL_GRAPH_DIR/Dave" \
        --output-path "$DOCS_DIR/Dave" \
        --warnings-as-errors

    echo "--- compiling Audio docc archive ---"
    "$DOCC_BIN" convert Sources/Audio/Audio.docc \
        --additional-symbol-graph-dir "$SYMBOL_GRAPH_DIR/Audio" \
        --output-path "$DOCS_DIR/Audio" \
        --warnings-as-errors
else
    echo "--- compiling docc via package plugin ---"
    export BMAUDIOKIT_DOCS=1
    export AUDIO_DOCS=1
    swift package --allow-writing-to-directory "$DOCS_DIR" \
        generate-documentation \
        --target Dave \
        --output-path "$DOCS_DIR/Dave"
    swift package --allow-writing-to-directory "$DOCS_DIR" \
        generate-documentation \
        --target Audio \
        --output-path "$DOCS_DIR/Audio"
fi

echo "=== docs build clean ==="
