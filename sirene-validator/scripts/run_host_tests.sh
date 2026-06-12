#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/host_tests/build"
cmake -S "$ROOT/host_tests" -B "$BUILD_DIR"
cmake --build "$BUILD_DIR"
"$BUILD_DIR/host_tests"
