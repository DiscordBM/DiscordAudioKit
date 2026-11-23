#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FAIL=0

check_file() {
    if [ ! -f "$ROOT/$1" ]; then
        echo "MISSING: $1"
        FAIL=1
    fi
}

check_file "Sources/C/CBoringSSL/LICENSE"
check_file "Sources/C/CBoringSSL/include/module.modulemap"
check_file "Sources/C/CMLSPP/LICENSE"
check_file "Sources/C/CMLSPP/include/namespace.h"
check_file "Sources/C/CLibDave/LICENSE"
check_file "Sources/C/CLibDave/include/dave.h"
check_file "Sources/C/CLibDave/include/module.modulemap"
check_file "Sources/C/COpus/LICENSE"
check_file "Sources/C/CMiniaudio/LICENSE"
check_file "THIRD_PARTY_NOTICES.md"
check_file "Vendor/VERSIONS.md"
check_file "Vendor/PATCHES.md"

if [ $FAIL -ne 0 ]; then
    echo "Vendor check failed."
    exit 1
fi

echo "Vendor check passed."
exit 0
