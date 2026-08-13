#!/usr/bin/env bash
set -euo pipefail

remove_if_installed() {
  local installed=() p
  for p in "$@"; do
    rpm -q "$p" >/dev/null 2>&1 && installed+=("$p")
  done
  ((${#installed[@]})) && dnf5 -y --setopt=install_weak_deps=False remove "${installed[@]}"
  return 0
}

# Preserve Fedora Silverblue's native language and input-method coverage.
# Kobold does not prune glibc/langpacks/IBus packages by locale; public images
# should inherit Fedora's supported localization behavior.

# Remove optional GUI/server/discovery components that do not belong to the host policy.
# The daemon/library distinction is intentional: core libraries may remain when required.
remove_if_installed \
  firefox firefox-langpacks \
  gnome-software gnome-software-rpm-ostree \
  gnome-tour gnome-connections gnome-contacts gnome-maps gnome-weather \
  gnome-calendar gnome-clocks gnome-characters gnome-logs gnome-font-viewer \
  gnome-extensions-app gnome-console \
  snapshot simple-scan cheese rhythmbox totem epiphany geary yelp papers evince \
  gnome-remote-desktop gnome-user-share rygel \
  malcontent-control malcontent-pam \
  fedora-workstation-repositories fedora-third-party fedora-bookmarks \
  openssh-server \
  ModemManager avahi avahi-tools cups cups-browsed system-config-printer \
  mcelog

# Explicit host package set. Toolchains/SDKs are intentionally not here.
dnf5 -y --setopt=install_weak_deps=False install \
  ca-certificates gnupg2 openssh-clients \
  flatpak \
  nautilus ptyxis gnome-text-editor loupe gnome-calculator gnome-disk-utility gnome-initial-setup \
  gnome-keyring xdg-desktop-portal-gnome xdg-desktop-portal-gtk \
  git git-lfs gh curl wget2-wget jq rsync ripgrep fd-find bat fzf unzip btop \
  smartmontools nvme-cli ethtool trivy lynis \
  podman buildah skopeo toolbox distrobox podlet passt slirp4netns fuse-overlayfs shadow-utils-subid \
  qemu-kvm libvirt-daemon-kvm libvirt-daemon-config-network \
  virt-manager virt-install virt-viewer edk2-ovmf swtpm swtpm-tools dnsmasq \
  firewalld tuned tuned-ppd \
  niri waybar fuzzel mako swaylock swayidle swaybg mate-polkit \
  brightnessctl playerctl wl-clipboard \
  powertop powerstat lm_sensors pciutils usbutils

# Key hardware/security support remains Fedora-native.
dnf5 -y --setopt=install_weak_deps=False install fwupd fprintd udisks2 upower bluez

# Assert critical desktop foundations survived removals.
rpm -q gnome-shell gnome-session gnome-control-center NetworkManager systemd >/dev/null
