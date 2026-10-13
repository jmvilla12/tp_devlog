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
    "05_lint.sh"
    "02_dependencies.sh"
    "03_compile.sh"
    "04_test.sh"
    "06_coverage.sh"
    "07_package.sh"
    "08_deploy.sh"
)

# Stage to run if the deploy stage fails
DEPLOY_SCRIPT="08_deploy.sh"
ROLLBACK_SCRIPT="09_rollback.sh"

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
        
        if [ "$script" = "$DEPLOY_SCRIPT" ]; then
            log ">>> Deployment failed, starting rollback ($ROLLBACK_SCRIPT)"
            set +e
            bash "$SCRIPTS_DIR/$ROLLBACK_SCRIPT" 2>&1 | tee -a "$LOG_FILE"
            rollback_rc=${PIPESTATUS[0]}
            set -e
            if [ "$rollback_rc" -eq 0 ]; then
                log "<<< Rollback SUCCEEDED, previous version restored"
            else
                log "<<< Rollback FAILED with exit code $rollback_rc"
            fi
        fi

        log "Pipeline $RUN_ID FAILED (total $((SECONDS - pipeline_start))s)"
        exit "$rc"
    fi
done

log "Pipeline $RUN_ID SUCCEEDED (total $((SECONDS - pipeline_start))s)"
exit 0