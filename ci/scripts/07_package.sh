#!/usr/bin/env bash
# Stage 07: package the application as an executable jar
set -euo pipefail

echo "=== [07] Packaging ==="

# Tests already ran in stage 04, no need to run them twice
if ./mvnw -B package -DskipTests; then
    echo "[07] OK: jar created:"
    ls -lh target/*.jar
    exit 0
else
    echo "[07] ERROR: packaging failed" >&2
    exit 1
fi