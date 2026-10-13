#!/usr/bin/env bash
# Shared settings and helpers for the deploy and rollback stages.
# Meant to be sourced, not executed: source ci/lib/common.sh

IMAGE_NAME="tp_devlog"
CONTAINER_NAME="tp_devlog-app"
APP_PORT=8080
HEALTH_URL="http://localhost:$APP_PORT/actuator/health"

# File holding the last image that was deployed AND passed the health check
STATE_DIR="ci/state"
LAST_GOOD_IMAGE_FILE="$STATE_DIR/last_successful_image"

# Poll the health endpoint until it reports UP, or give up after the timeout.
# Returns 0 if healthy, 1 otherwise.
wait_for_health() {
    local timeout_seconds=60
    local interval=2
    local elapsed=0

    echo "Waiting for $HEALTH_URL to report UP (timeout ${timeout_seconds}s)..."
    while [ "$elapsed" -lt "$timeout_seconds" ]; do
        if curl -fs "$HEALTH_URL" | grep -q '"status":"UP"'; then
            echo "Application is healthy after ${elapsed}s"
            return 0
        fi
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done

    echo "Application did not become healthy within ${timeout_seconds}s" >&2
    return 1
}

# Stop and remove the app container if it exists
remove_container() {
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}