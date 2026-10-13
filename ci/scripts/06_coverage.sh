#!/usr/bin/env bash
# Stage 06: test coverage report and quality gate with JaCoCo (R&D)
# Relies on target/jacoco.exec produced by stage 04 (tests)
set -euo pipefail

echo "=== [06] Test coverage (JaCoCo) ==="

if [ ! -f target/jacoco.exec ]; then
    echo "[06] ERROR: target/jacoco.exec not found, run stage 04 first" >&2
    exit 1
fi

if ./mvnw -B jacoco:report jacoco:check; then
    echo "[06] OK: coverage threshold met (report: target/site/jacoco/index.html)"
    exit 0
else
    echo "[06] ERROR: coverage below threshold" >&2
    exit 1
fi