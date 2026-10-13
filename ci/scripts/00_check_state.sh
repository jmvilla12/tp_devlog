#!/usr/bin/env bash
# Stage 00: check the state of the project before building
# (git repository, manifest present, in sync with the remote, uncommitted changes)
set -euo pipefail

echo "=== [00] Checking project state ==="

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[00] ERROR: not a git repository" >&2
    exit 1
fi

if [ ! -f pom.xml ]; then
    echo "[00] ERROR: pom.xml not found at project root" >&2
    exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "Branch: $BRANCH"
echo "Commit: $(git log -1 --format='%h %s (%an, %ar)')"

# Compare with the remote branch, if the remote can be reached
if git fetch --quiet origin 2>/dev/null; then
    UPSTREAM="origin/$BRANCH"
    if git rev-parse --verify --quiet "$UPSTREAM" >/dev/null; then
        BEHIND="$(git rev-list --count "HEAD..$UPSTREAM")"
        AHEAD="$(git rev-list --count "$UPSTREAM..HEAD")"
        echo "Compared to $UPSTREAM: $AHEAD ahead, $BEHIND behind"
        if [ "$BEHIND" -gt 0 ]; then
            echo "[00] ERROR: local branch is behind $UPSTREAM, run 'git pull' first" >&2
            exit 1
        fi
        if [ "$AHEAD" -gt 0 ]; then
            echo "[00] WARNING: $AHEAD local commit(s) not pushed yet"
        fi
    else
        echo "[00] WARNING: no remote branch $UPSTREAM to compare with"
    fi
else
    echo "[00] WARNING: could not reach the remote, skipping sync check"
fi

if [ -n "$(git status --porcelain)" ]; then
    echo "[00] WARNING: uncommitted changes, the build won't match commit $(git rev-parse --short HEAD):"
    git status --short
fi

echo "[00] OK: project state checked"
exit 0