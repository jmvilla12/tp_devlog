#!/usr/bin/env bash
# Stage 05: static code analysis with Checkstyle (R&D)
set -euo pipefail

echo "=== [05] Linting (Checkstyle) ==="

if ./mvnw -B checkstyle:check; then
    echo "[05] OK: no Checkstyle violations"
    exit 0
else
    echo "[05] ERROR: Checkstyle violations found (see report above)" >&2
    exit 1
fi