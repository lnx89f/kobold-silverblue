#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
installer=${INSTALLER_IMAGE:?INSTALLER_IMAGE is required}
payload=${PAYLOAD_IMAGE:?PAYLOAD_IMAGE is required}
output=${OUTPUT_DIR:-$root/output/iso}
iso_name=${ISO_NAME:-}
builder='ghcr.io/osbuild/image-builder-cli:latest@sha256:3fb4516c71fa6ff000c521702184137b624f10475c07a5ad1983c69f79095e6d'

[[ $EUID -eq 0 ]] || { printf 'run as root (for example with sudo)\n' >&2; exit 1; }
[[ "$installer" != *' '* && "$payload" != *' '* ]]
[[ -z "$iso_name" || "$iso_name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*\.iso$ ]]
podman image exists "$installer" || { printf 'installer image is missing: %s\n' "$installer" >&2; exit 1; }
podman image exists "$payload" || { printf 'payload image is missing: %s\n' "$payload" >&2; exit 1; }

mkdir -p "$output"
output=$(realpath "$output")
[[ -z "$(find "$output" -mindepth 1 -maxdepth 1 -print -quit)" ]] || {
  printf 'ISO output directory must be empty: %s\n' "$output" >&2
  exit 1
}

podman run --rm --privileged \
  --security-opt label=type:unconfined_t \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "$output:/output" \
  "$builder" build \
  --output-dir /output \
  --bootc-ref "$installer" \
  --bootc-build-ref "$installer" \
  --bootc-installer-payload-ref "$payload" \
  --bootc-default-fs btrfs \
  --bootc-no-default-kernel-args \
  --with-manifest \
  --with-buildlog \
  bootc-generic-iso

iso=$(find "$output" -maxdepth 1 -type f -name '*.iso' -print -quit)
[[ -n "$iso" ]]
if [[ -n "$iso_name" ]]; then
  mv "$iso" "$output/$iso_name"
  iso="$output/$iso_name"
fi
sha256sum "$iso" >"${iso}-CHECKSUM"
printf '%s\n' "$iso"
