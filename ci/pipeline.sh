#!/usr/bin/env bash
# CI/CD pipeline orchestrator: runs each script in order,
# stops at the first failure and writes everything to a log file.
set -euo pipefail

# Always run from the project root, wherever the script is called from
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCRIPTS_DIR="ci/scripts"
LOG_DIR="ci/logs"
RUN_ID="$(date '+%Y%m%d_%H%M%S')"
LOG_FILE="$LOG_DIR/pipeline_$RUN_ID.log"

# Scripts, in execution order
SCRIPTS=(
    "01_validate.sh"
    "02_dependencies.sh"
    "03_compile.sh"
    "04_test.sh"
)

mkdir -p "$LOG_DIR"

# Print a timestamped message to the console and append it to the log file
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Pipeline $RUN_ID started (commit $(git rev-parse --short HEAD))"
pipeline_start=$SECONDS

for script in "${SCRIPTS[@]}"; do
    log ">>> Script $script started"
    script_start=$SECONDS

    # Run the script, sending its output to both console and log file.
    # set -e is disabled here so a failing script doesn't kill the orchestrator
    # before we can log the failure.
    set +e
    bash "$SCRIPTS_DIR/$script" 2>&1 | tee -a "$LOG_FILE"
    rc=${PIPESTATUS[0]}
    set -e

    if [ "$rc" -eq 0 ]; then
        log "<<< Script $script SUCCEEDED ($((SECONDS - script_start))s)"
    else
        log "<<< Script $script FAILED with exit code $rc ($((SECONDS - script_start))s)"
        log "Pipeline $RUN_ID FAILED (total $((SECONDS - pipeline_start))s)"
        exit "$rc"
    fi
done

log "Pipeline $RUN_ID SUCCEEDED (total $((SECONDS - pipeline_start))s)"
exit 0