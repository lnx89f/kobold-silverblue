#!/usr/bin/env bash
set -euo pipefail
image=${1:-localhost/kobold:dev}
command -v podman >/dev/null || { echo 'podman is required' >&2; exit 1; }
podman image exists "$image" || { printf 'Image not found: %s\n' "$image" >&2; exit 1; }
podman run --rm --entrypoint /usr/libexec/kobold-image-invariants "$image" --build
podman run --rm --privileged --entrypoint bootc "$image" container lint --fatal-warnings
