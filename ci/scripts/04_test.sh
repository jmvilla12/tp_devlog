#!/usr/bin/env bash
# Script 04: run unit tests
set -euo pipefail

echo "=== [04] Running unit tests ==="

if ./mvnw -B test; then
    echo "[04] OK: all tests passed"
    exit 0
else
    echo "[04] ERROR: some tests failed" >&2
    exit 1
fi