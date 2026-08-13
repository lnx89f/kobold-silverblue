#!/usr/bin/env bash
set -euo pipefail

[[ -s /etc/flatpak/remotes.d/flathub.flatpakrepo ]]

# Fedora's OCI Flatpak remote requires a graphical/session D-Bus authenticator.
# Kobold selects Flathub, so keep Fedora's automatic remote out of the candidate.
systemctl mask flatpak-add-fedora-repos.service

# Applications are user-selected. Do not automatically provision Firefox or
# any other Flatpak from the OS image.
if systemctl list-unit-files flatpak-preinstall.service --no-legend 2>/dev/null | grep -q '^flatpak-preinstall.service'; then
  systemctl mask flatpak-preinstall.service
fi
