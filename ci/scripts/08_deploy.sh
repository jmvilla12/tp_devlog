#!/usr/bin/env bash
# Stage 08: build the Docker image and deploy it as a container,
# then verify the deployment with the actuator health check
set -euo pipefail
source ci/lib/common.sh

# Tag = commit it was built from (traceability) + timestamp (unique per build,
# so a rebuild never overwrites the image we may need to roll back to)
IMAGE_TAG="$(git rev-parse --short HEAD)-$(date '+%Y%m%d%H%M%S')"
IMAGE="$IMAGE_NAME:$IMAGE_TAG"

echo "=== [08] Deploying $IMAGE ==="

echo "Building Docker image..."
if ! docker build -t "$IMAGE" .; then
    echo "[08] ERROR: docker build failed" >&2
    exit 1
fi

echo "Replacing container $CONTAINER_NAME..."
remove_container
if ! docker run -d --name "$CONTAINER_NAME" -p "$APP_PORT:8080" "$IMAGE"; then
    echo "[08] ERROR: could not start container" >&2
    exit 1
fi

if wait_for_health; then
    mkdir -p "$STATE_DIR"
    echo "$IMAGE" > "$LAST_GOOD_IMAGE_FILE"
    echo "[08] OK: $IMAGE deployed and healthy on port $APP_PORT"
    exit 0
else
    echo "--- Last logs of the failed container ---" >&2
    docker logs --tail 30 "$CONTAINER_NAME" >&2 || true
    echo "[08] ERROR: deployment of $IMAGE is unhealthy" >&2
    exit 1
fi