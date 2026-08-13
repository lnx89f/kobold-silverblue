#!/usr/bin/env bash
set -euo pipefail

image=${1:-localhost/kobold:dev}
out=${2:-output/qcow2}
mkdir -p "$out"
command -v podman >/dev/null || { echo 'podman required' >&2; exit 1; }

# Unified image-builder replaces bootc-image-builder.
# Keep the builder digest pinned; Renovate may update it.
builder='ghcr.io/osbuild/image-builder-cli:latest@sha256:fc98309168b269e84ee53e720ba774af824143ea6b69c66173a6866aaf785181'

sudo podman run --rm --privileged \
  --security-opt label=type:unconfined_t \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "$(realpath "$out"):/output" \
  "$builder" build \
  --output-dir /output \
  --bootc-ref "$image" \
  --bootc-default-fs btrfs \
  qcow2
