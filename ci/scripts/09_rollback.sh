#!/usr/bin/env bash
# Stage 09: roll back to the last image that was successfully deployed.
# Called by the pipeline only when stage 08 fails.
set -euo pipefail
source ci/lib/common.sh

echo "=== [09] Rolling back ==="

if [ ! -f "$LAST_GOOD_IMAGE_FILE" ]; then
    echo "[09] ERROR: no previous successful deployment to roll back to" >&2
    remove_container
    exit 1
fi

PREVIOUS_IMAGE="$(cat "$LAST_GOOD_IMAGE_FILE")"
echo "Restoring $PREVIOUS_IMAGE..."

remove_container
if ! docker run -d --name "$CONTAINER_NAME" -p "$APP_PORT:8080" "$PREVIOUS_IMAGE"; then
    echo "[09] ERROR: could not start previous image $PREVIOUS_IMAGE" >&2
    exit 1
fi

if wait_for_health; then
    echo "[09] OK: rolled back to $PREVIOUS_IMAGE"
    exit 0
else
    echo "[09] ERROR: rollback to $PREVIOUS_IMAGE is unhealthy too" >&2
    exit 1
fi