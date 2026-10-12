#!/usr/bin/env bash
# Stage 02: resolve dependencies
set -euo pipefail

echo "=== [02] Resolving dependencies ==="

if ./mvnw -B dependency:tree; then
    echo "[02] OK: dependencies resolved"
    exit 0
else
    echo "[02] ERROR: could not resolve dependencies" >&2
    exit 1
fi