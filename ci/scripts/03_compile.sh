#!/usr/bin/env bash
# Script 03: compile sources
set -euo pipefail

echo "=== [03] Compiling ==="

if ./mvnw -B compile; then
    echo "[03] OK: compilation succeeded"
    exit 0
else
    echo "[03] ERROR: compilation failed" >&2
    exit 1
fi