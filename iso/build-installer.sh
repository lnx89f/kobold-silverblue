#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
payload=${PAYLOAD_IMAGE:?PAYLOAD_IMAGE is required}
target=${TARGET_IMAGE:-$payload}
installer_tag=${INSTALLER_TAG:-dev}
installer="localhost/kobold-installer:${installer_tag}"

[[ $EUID -eq 0 ]] || { printf 'run as root (for example with sudo)\n' >&2; exit 1; }
[[ "$payload" != *' '* && "$target" != *' '* && "$installer_tag" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$ ]]
podman image exists "$payload" || { printf 'payload is not present in root container storage: %s\n' "$payload" >&2; exit 1; }

podman build --pull=always --format oci \
  --build-arg "PAYLOAD_IMAGE=${payload}" \
  --build-arg "TARGET_IMAGE=${target}" \
  -f "$root/iso/Containerfile" \
  -t "$installer" \
  "$root"

podman run --rm --entrypoint /usr/bin/test "$installer" \
  -x /usr/libexec/kobold-mksquashfs-selinux
podman run --rm --entrypoint /usr/bin/test "$installer" \
  -f /usr/lib/image-builder/bootc/iso.yaml
podman run --rm --privileged --entrypoint bootc "$installer" \
  container lint --fatal-warnings --skip nonempty-boot

printf '%s\n' "$installer"
