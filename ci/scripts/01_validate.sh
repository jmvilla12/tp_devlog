#!/usr/bin/env bash
# Script 01: validate the manifest (pom.xml)
set -euo pipefail

echo "=== [01] Validating manifest (pom.xml) ==="

if ./mvnw -B validate; then
    echo "[01] OK: pom.xml is valid"
    exit 0
else
    echo "[01] ERROR: pom.xml is invalid or project is inconsistent" >&2
    exit 1
fi