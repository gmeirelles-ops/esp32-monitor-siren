#!/usr/bin/env bash
# Espelha os jobs principais do CI (.github/workflows/ci.yml).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0

echo "==> Flutter tests (sirene_app)"
(
  cd "$ROOT/sirene_app"
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs
  flutter test
) || FAILED=1

echo "==> Firmware host tests"
"$ROOT/sirene-validator/scripts/run_host_tests.sh" || FAILED=1

if [[ "$FAILED" -ne 0 ]]; then
  echo "CI local: FAILED" >&2
  exit 1
fi

echo "CI local: OK"
