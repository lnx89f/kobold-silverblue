#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
containerfile=${1:-$root/Containerfile}
command -v podman >/dev/null || { echo 'podman required' >&2; exit 1; }
[[ -f "$containerfile" ]] || { echo "Containerfile not found: $containerfile" >&2; exit 1; }

declaration=$(sed -nE 's/^ARG (BASE_IMAGE|INSTALLER_BASE)="([^"]+)"$/\1 \2/p' "$containerfile" | head -n1)
read -r base_kind base <<<"$declaration"
case "$base_kind" in
  BASE_IMAGE)
    expected_repository=quay.io/fedora/fedora-silverblue
    [[ "$base" =~ ^quay\.io/fedora/fedora-silverblue:44@sha256:[a-f0-9]{64}$ ]] || {
      printf 'Unexpected Fedora Silverblue base: %s\n' "$base" >&2
      exit 1
    }
    ;;
  INSTALLER_BASE)
    expected_repository=quay.io/fedora/fedora-bootc
    [[ "$base" =~ ^quay\.io/fedora/fedora-bootc:44@sha256:[a-f0-9]{64}$ ]] || {
      printf 'Unexpected Fedora bootc installer base: %s\n' "$base" >&2
      exit 1
    }
    ;;
  *)
    printf 'No supported pinned Fedora base declaration in %s\n' "$containerfile" >&2
    exit 1
    ;;
esac

declared_digest=${base##*@}

# Pull the exact immutable reference. Do not substitute the floating :44 tag here.
podman pull --quiet "$base" >/dev/null

# The pulled object must expose the same repository digest requested by the source.
repo_digests=$(podman image inspect --format '{{range .RepoDigests}}{{println .}}{{end}}' "$base")
grep -Fqx "${expected_repository}@${declared_digest}" <<<"$repo_digests" || {
  printf 'Pulled image does not match declared Fedora digest: %s\n' "$declared_digest" >&2
  printf '%s\n' "$repo_digests" >&2
  exit 1
}

if [[ "$base_kind" == BASE_IMAGE ]]; then
  # Verify that the payload base is actually Silverblue, not merely an object
  # located under the expected registry path.
  podman run --rm --entrypoint /usr/bin/rpm "$base" \
    -q fedora-release-silverblue bootc >/dev/null
  podman run --rm --entrypoint /usr/bin/bash "$base" -ceu \
    'grep -Fqx "ID=fedora" /usr/lib/os-release; grep -Fqx "VARIANT_ID=silverblue" /usr/lib/os-release'
  description='Fedora-published Silverblue payload base'
else
  # The live environment is deliberately distinct from the Kobold payload.
  podman run --rm --entrypoint /usr/bin/rpm "$base" \
    -q bootc kernel-core selinux-policy-targeted >/dev/null
  podman run --rm --entrypoint /usr/bin/bash "$base" -ceu \
    'grep -Fqx "ID=fedora" /usr/lib/os-release; test -s /etc/selinux/targeted/contexts/files/file_contexts'
  description='Fedora-published bootc installer base'
fi

printf '[OK] %s pinned by digest: %s\n' "$description" "$base"
