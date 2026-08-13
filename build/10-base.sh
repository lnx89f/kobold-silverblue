#!/usr/bin/env bash
set -euo pipefail

[[ -d /ctx/files ]] || { echo 'missing /ctx/files' >&2; exit 1; }

# Fedora Silverblue intentionally ships workstation opt-in metadata for third-party
# software. Kobold does not use that facility (GNOME Software is absent), so remove
# the owning packages before enforcing the final repository policy. This is
# package-aware: do not delete RPM-owned .repo files by hand.
remove_base_package_if_installed() {
  local package=$1
  if rpm -q "$package" >/dev/null 2>&1; then
    dnf5 -y --setopt=install_weak_deps=False remove "$package"
  fi
}
remove_base_package_if_installed fedora-workstation-repositories
remove_base_package_if_installed fedora-third-party

# Fail closed on any repository file that is not RPM-owned by Fedora's repository
# packages. This is stricter than trusting a filename prefix.
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

cp -a /ctx/files/. /
chmod 0755 /usr/bin/pinguim /usr/libexec/kobold-* 2>/dev/null || :

# Immutable base should not contain human/personal state.
find /etc/NetworkManager/system-connections -maxdepth 1 -type f -name '*.nmconnection' -delete 2>/dev/null || :
rm -f /root/.docker/config.json /root/.config/containers/auth.json 2>/dev/null || :
