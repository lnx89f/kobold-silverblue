#!/usr/bin/env bash
set -euo pipefail

# Never persist the temporary Microsoft build repository.
! find /etc/yum.repos.d -maxdepth 1 -type f \( -iname '*vscode*' -o -iname '*microsoft*' \) -print -quit | grep -q .

# Workstation third-party opt-in infrastructure must not survive composition.
! rpm -q fedora-workstation-repositories >/dev/null 2>&1 || { echo 'fedora-workstation-repositories persisted' >&2; exit 1; }
! rpm -q fedora-third-party >/dev/null 2>&1 || { echo 'fedora-third-party persisted' >&2; exit 1; }

# Fedora repositories only, based on RPM ownership rather than filename patterns.
while IFS= read -r repo; do
  [[ -n "$repo" ]] || continue
  owner=$(rpm -qf --qf '%{NAME}' "$repo" 2>/dev/null) || {
    printf 'Unowned RPM repository file: %s\n' "$repo" >&2
    exit 1
  }
  case "$owner" in
    fedora-repos|fedora-repos-archive) ;;
    *)
      printf 'Repository file is not owned by an allowed Fedora repo package: %s (owner=%s)\n' "$repo" "$owner" >&2
      exit 1
      ;;
  esac
done < <(find /etc/yum.repos.d -maxdepth 1 -type f -name '*.repo' -print 2>/dev/null | sort)

# Preserve the initial authselect integrity checksum as image-owned seed data;
# tmpfiles recreates it only when mutable /var has no checksum yet.
install -Dm0644 /var/lib/authselect/checksum /usr/lib/kobold/state/authselect-checksum

# Clean composition-only runtime state, caches, logs and mutable lock files.
dnf5 clean all
rm -rf \
  /run/dnf /run/gluster /run/selinux-policy /run/systemd/systemd-units-load \
  /tmp/* /var/tmp/* \
  /var/cache/ibus /var/cache/ldconfig /var/cache/libvirt \
  /var/cache/powertop /var/cache/swcatalog \
  /var/lib/authselect/checksum /var/lib/dnf/system-repo.lock /var/lib/dnf/repos \
  /var/log/dnf5.log*

/usr/libexec/kobold-image-invariants --build
