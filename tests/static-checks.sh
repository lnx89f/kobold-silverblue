#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
failures=0
ok() { printf '[OK] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*" >&2; failures=$((failures + 1)); }

required=(
  Containerfile README.md KOBOLD-SPEC.md AGENTS.md renovate.json
  ci/verify-fedora-base.sh
  docs/ARCHITECTURE.md docs/SECURITY.md docs/TUNING.md docs/NETWORK.md docs/UPDATE.md docs/ISO.md docs/RECOVERY.md docs/SOURCE_REUSE.md
  build/10-base.sh build/20-packages.sh build/30-vscode.sh build/40-services.sh build/50-security.sh build/60-desktop.sh build/70-tuning.sh build/80-flatpak.sh build/90-finalize.sh
  files/etc/hostname files/etc/bluetooth/main.conf files/etc/sysctl.d/60-kobold-security.conf
  files/etc/dconf/profile/gdm files/etc/dconf/db/gdm.d/01-kobold-logo
  files/etc/NetworkManager/conf.d/20-kobold-privacy.conf files/etc/systemd/resolved.conf.d/60-kobold.conf
  files/etc/tuned/ppd.conf files/etc/tuned/profiles/kobold-powersave/tuned.conf files/etc/lynis/custom.prf
  files/usr/lib/systemd/system/kobold-firewall-first-boot.service
  files/usr/lib/tmpfiles.d/kobold-state.conf
  files/etc/flatpak/remotes.d/flathub.flatpakrepo
  files/usr/share/glib-2.0/schemas/90_kobold.gschema.override
  files/usr/share/backgrounds/kobold/kobold-wallpaper.jpg files/usr/share/kobold/branding/kobold-gdm-logo.png
  files/usr/bin/pinguim files/usr/libexec/kobold-configure-firewall files/usr/libexec/kobold-configure-services files/usr/libexec/kobold-image-invariants
  tests/image-invariants.sh tests/build-qcow2-rootful.sh tests/boot-qcow2-smoke.sh tests/iso-acceptance.md
  iso/Containerfile iso/configure-installer.sh iso/iso.yaml iso/bootc-installer-wrapper.sh iso/kobold-installer.tmpfiles iso/kobold-installer.sysusers iso/mksquashfs-selinux.py
  iso/build-installer.sh iso/build-iso.sh iso/README.md
  .github/workflows/validate.yml .github/workflows/build-testing.yml .github/workflows/promote-stable.yml .github/workflows/build-iso.yml
)
for path in "${required[@]}"; do [[ -e "$root/$path" ]] || fail "missing required file: $path"; done

mapfile -d '' scripts < <(find "$root/build" "$root/tests" "$root/iso" -type f -name '*.sh' -print0; find "$root/files/usr/bin" "$root/files/usr/libexec" -type f -print0)
for script in "${scripts[@]}"; do
  [[ "$(head -n1 "$script")" == '#!/usr/bin/env bash' ]] || fail "bad shebang: ${script#$root/}"
  head -n5 "$script" | grep -Fq 'set -euo pipefail' || fail "strict mode missing: ${script#$root/}"
  bash -n "$script" || fail "Bash syntax error: ${script#$root/}"
  [[ -x "$script" ]] || fail "not executable: ${script#$root/}"
done
python3 - "$root/iso/mksquashfs-selinux.py" <<'PY' || fail 'installer SELinux SquashFS helper has invalid Python syntax'
import pathlib, sys
source = pathlib.Path(sys.argv[1]).read_text()
compile(source, sys.argv[1], 'exec')
PY
[[ -x "$root/iso/mksquashfs-selinux.py" ]] || fail 'installer SELinux SquashFS helper is not executable'

# Base must be the Fedora-published Silverblue 44 OCI and digest pinned.
grep -Eq '^ARG BASE_IMAGE="quay.io/fedora/fedora-silverblue:44@sha256:[a-f0-9]{64}"$' "$root/Containerfile" || fail 'Fedora-published Silverblue base is not digest-pinned'
grep -Eq '^ARG INSTALLER_BASE="quay.io/fedora/fedora-bootc:44@sha256:[a-f0-9]{64}"$' "$root/iso/Containerfile" || fail 'Fedora bootc installer base is not digest-pinned'
grep -Fq 'quay.io/fedora/fedora-silverblue' "$root/renovate.json" || fail 'Renovate is not tracking Fedora-published Silverblue'
grep -Fq 'use_geolocation = False' "$root/iso/configure-installer.sh" || fail 'Anaconda geolocation is not disabled'
grep -Fq 'inst.geoloc=0' "$root/iso/iso.yaml" || fail 'installer boot entry does not disable geolocation'
if grep -Eq 'inst\.lang=|^[[:space:]]*lang[[:space:]]+' "$root/iso/iso.yaml" "$root/iso/configure-installer.sh"; then fail 'installer forces a project-wide language'; fi
if grep -Eq 'glibc-all-langpacks|extra_glibc|extra_langpacks|ime_pkgs|Non-PT/EN|PT/EN language' "$root/build/20-packages.sh"; then fail 'Fedora localization coverage is being pruned'; fi
grep -Fq 'bootc container lint --fatal-warnings --skip nonempty-boot' "$root/iso/Containerfile" || fail 'installer lint exception is not limited to its required /boot content'
grep -Fq 'iso/iso.yaml /usr/lib/image-builder/bootc/iso.yaml' "$root/iso/Containerfile" || fail 'ISO metadata is not copied to the canonical Image Builder path'
grep -Fq 'kobold-mksquashfs-selinux' "$root/iso/Containerfile" || fail 'installer SquashFS does not use its SELinux labeling helper'
grep -Fq 'SELABEL_OPT_PATH' "$root/iso/mksquashfs-selinux.py" || fail 'installer labels are not sourced from its own Fedora policy'
grep -Fq 'selabel_lookup_raw' "$root/iso/mksquashfs-selinux.py" || fail 'installer labels do not use raw target-policy lookups'
grep -Fq 'security.selinux' "$root/iso/mksquashfs-selinux.py" || fail 'installer SquashFS SELinux xattrs are not generated'
grep -Fq 'exclude @ type(l)' "$root/iso/mksquashfs-selinux.py" || fail 'source symlinks are not replaced by labeled pseudo-files'
grep -Fq -- '--bootc-build-ref "$installer"' "$root/iso/build-iso.sh" || fail 'installer is not the explicit Image Builder build root'
grep -Fq -- '--bootc-no-default-kernel-args' "$root/iso/build-iso.sh" || fail 'unsafe upstream default ISO kernel arguments are not disabled'
grep -Fq 'bootc-generic-iso' "$root/iso/build-iso.sh" || fail 'current generic ISO type is missing'
grep -Fq 'mount --bind "$scratch" /var/tmp' "$root/iso/bootc-installer-wrapper.sh" || fail 'containers/image blob scratch is not target-backed'
grep -Fq 'target_index=-1' "$root/iso/bootc-installer-wrapper.sh" || fail 'bootc wrapper does not scan argv for the Anaconda physical root'
grep -Fq '[[ ${args[$i]} == /mnt/sysimage ]]' "$root/iso/bootc-installer-wrapper.sh" || fail 'bootc wrapper does not detect /mnt/sysimage independently of argv order'
grep -Fq 'bootc_args+=(--skip-finalize)' "$root/iso/bootc-installer-wrapper.sh" || fail 'bootc scratch wrapper does not defer filesystem finalization'
if grep -Fq '${!#} == /mnt/sysimage' "$root/iso/bootc-installer-wrapper.sh"; then fail 'bootc wrapper incorrectly assumes /mnt/sysimage is the final argv element'; fi
grep -Fq 'TMPDIR=/var/tmp "$real_bootc" "${bootc_args[@]}"' "$root/iso/bootc-installer-wrapper.sh" || fail 'target-backed bootc scratch setup is missing'
grep -Fq 'target_source=$(findmnt' "$root/iso/bootc-installer-wrapper.sh" || fail 'bootc scratch target mount validation is missing'
grep -Fq 'mount --bind "$scratch" "$scratch"' "$root/iso/bootc-installer-wrapper.sh" || fail 'bootc scratch must be an allowed target mount point'
grep -Fq 'umount /var/tmp' "$root/iso/bootc-installer-wrapper.sh" || fail 'containers/image blob scratch cleanup is missing'
grep -Fq 'umount "$scratch"' "$root/iso/bootc-installer-wrapper.sh" || fail 'bootc scratch mount cleanup is missing'
grep -Fq 'rmdir "$scratch"' "$root/iso/bootc-installer-wrapper.sh" || fail 'target-backed bootc scratch cleanup is missing'
grep -Fq 'assert_scratch_released' "$root/iso/bootc-installer-wrapper.sh" || fail 'bootc scratch release verification is missing'
grep -Fq 'fstrim --quiet-unsupported -v "$path"' "$root/iso/bootc-installer-wrapper.sh" || fail 'deferred bootc fstrim semantics are missing'
grep -Fq 'mount -o remount,ro "$path"' "$root/iso/bootc-installer-wrapper.sh" || fail 'deferred bootc read-only remount is missing'
grep -Fq 'if [[ $magic != 4d44 ]]' "$root/iso/bootc-installer-wrapper.sh" || fail 'deferred bootc VFAT freeze exception is missing'
grep -Fq 'fsfreeze -f "$path"' "$root/iso/bootc-installer-wrapper.sh" || fail 'deferred bootc filesystem freeze is missing'
grep -Fq 'fsfreeze -u "$path"' "$root/iso/bootc-installer-wrapper.sh" || fail 'deferred bootc filesystem thaw is missing'
grep -Fq 'finalize_filesystem root .' "$root/iso/bootc-installer-wrapper.sh" || fail 'deferred bootc root finalization is missing'
grep -Fq 'finalize_filesystem boot boot' "$root/iso/bootc-installer-wrapper.sh" || fail 'deferred bootc separate /boot finalization is missing'
if grep -RniE -- '(enforcing|selinux)=0' "$root/iso/Containerfile" "$root/iso/configure-installer.sh" "$root/iso/iso.yaml" "$root/iso/build-installer.sh" "$root/iso/build-iso.sh"; then fail 'installer pipeline disables SELinux'; fi
grep -Fq '/var/log/dnf5.log*' "$root/iso/Containerfile" || fail 'installer composition logs are not cleaned'
grep -Fq '/var/lib/iscsi' "$root/iso/kobold-installer.tmpfiles" || fail 'installer iSCSI state lacks a tmpfiles declaration'
grep -Fq '/var/log/blivet-gui' "$root/iso/kobold-installer.tmpfiles" || fail 'installer Blivet log directory lacks a tmpfiles declaration'
grep -Fq 'u install 0 "Anaconda installer"' "$root/iso/kobold-installer.sysusers" || fail 'Anaconda installer account lacks a sysusers declaration'
if grep -Eq 'bootc container lint.*--skip (nonempty-run-tmp|var-log|var-tmpfiles)' "$root/iso/Containerfile"; then fail 'installer suppresses composition-residue lint checks'; fi

# The former SIG mirror/build stream must not return as an implicit base.
if grep -RniI -- 'quay.io/fedora-ostree-desktops' "$root/Containerfile" "$root/iso/Containerfile" "$root/renovate.json"; then fail 'legacy Fedora Atomic Desktops SIG base reference found'; fi

# No unwanted runtime inheritance.
for forbidden in 'ghcr.io/ublue-os/bluefin' 'ghcr.io/projectbluefin/common' 'ghcr.io/ublue-os/brew' 'rpmfusion' 'linuxbrew' 'homebrew'; do
  matches=$(grep -RniI --exclude='README.md' -- "$forbidden" "$root/Containerfile" "$root/build" "$root/iso/Containerfile" "$root/iso/configure-installer.sh" || :)
  [[ -z "$matches" ]] || { printf '%s\n' "$matches" >&2; fail "forbidden runtime reference: $forbidden"; }
done

# Security/tuning separation and selected policies.
grep -Fqx 'kernel.kexec_load_disabled = 1' "$root/files/etc/sysctl.d/60-kobold-security.conf" || fail 'kexec hardening missing'
grep -Fqx 'kernel.unprivileged_bpf_disabled = 1' "$root/files/etc/sysctl.d/60-kobold-security.conf" || fail 'unprivileged BPF hardening missing'
grep -Fqx 'net.ipv6.conf.all.accept_source_route = -1' "$root/files/etc/sysctl.d/60-kobold-security.conf" || fail 'IPv6 source-route policy incorrect'
if grep -Eq '^vm\.(swappiness|watermark_|page-cluster|vfs_cache_pressure|dirty_(background_)?bytes)' "$root/files/etc/sysctl.d/60-kobold-security.conf"; then fail 'performance VM tuning leaked into security sysctl'; fi
[[ ! -e "$root/files/etc/systemd/zram-generator.conf" ]] || fail 'custom ZRAM override must be absent'
[[ ! -e "$root/files/etc/modprobe.d/10-kobold-audio.conf" ]] || fail 'alpha audio power override must be absent'
grep -Fqx 'wifi.powersave=3' "$root/files/etc/NetworkManager/conf.d/20-kobold-privacy.conf" || fail 'Wi-Fi powersave must be enabled'
! grep -Rqs 'USB_AUTOSUSPEND=1' "$root/files" || fail 'forced USB autosuspend found'
! grep -Fq '[script]' "$root/files/etc/tuned/profiles/kobold-powersave/tuned.conf" || fail 'Kobold power-saver must not inherit TuneD USB helper script'
grep -Fq 'C /var/lib/authselect/checksum 0644 root root - /usr/lib/kobold/state/authselect-checksum' "$root/files/usr/lib/tmpfiles.d/kobold-state.conf" || fail 'authselect mutable-state seed missing'
grep -Fq '/run/selinux-policy' "$root/build/90-finalize.sh" || fail 'composition runtime-state cleanup missing'
grep -Fq '/var/log/dnf5.log' "$root/build/90-finalize.sh" || fail 'composition log cleanup missing'

# Product decisions.
grep -Fq 'fedora-workstation-repositories' "$root/build/10-base.sh" || fail 'package-aware workstation repository removal missing'
grep -Fq 'fedora-workstation-repositories' "$root/files/usr/libexec/kobold-image-invariants" || fail 'workstation repository invariant missing'
grep -Fq 'openssh-server' "$root/build/20-packages.sh" || fail 'explicit openssh-server removal missing'
grep -Fq 'gnome-software' "$root/build/20-packages.sh" || fail 'explicit GNOME Software removal missing'
grep -Fq 'niri waybar fuzzel' "$root/build/20-packages.sh" || fail 'Niri stack missing'
grep -Fq 'virtqemud.service virtnetworkd.service virtstoraged.service' "$root/files/usr/libexec/kobold-configure-services" || fail 'modular libvirt services are not explicitly disabled'
grep -Fq 'modular libvirt service enabled at boot' "$root/files/usr/libexec/kobold-image-invariants" || fail 'modular libvirt boot invariant missing'
[[ ! -e "$root/files/etc/niri/config.kdl" ]] || fail 'Niri config must not be imposed'
[[ ! -e "$root/files/usr/share/flatpak/preinstall.d/kobold.preinstall" ]] || fail 'Firefox Flatpak preinstall must be absent'
[[ ! -e "$root/files/usr/lib/systemd/system/kobold-flatpak-preinstall.service" ]] || fail 'legacy Kobold Flatpak preinstall service must be absent'
grep -Fq 'systemctl mask flatpak-add-fedora-repos.service' "$root/build/80-flatpak.sh" || fail 'Fedora Flatpak remote auto-add is not masked'
grep -Fq 'ConditionPathExists=!/var/lib/kobold/firewall-default-applied' "$root/files/usr/lib/systemd/system/kobold-firewall-first-boot.service" || fail 'firewall reconciliation lacks its one-time marker condition'
grep -Fq 'ExecStart=/usr/libexec/kobold-configure-firewall' "$root/files/usr/lib/systemd/system/kobold-firewall-first-boot.service" || fail 'first-boot firewall reconciliation command missing'
grep -Fq 'firewall-offline-cmd --get-default-zone' "$root/files/usr/libexec/kobold-configure-firewall" || fail 'firewall default-zone reconciliation is not idempotent'
grep -Fq 'services:service-from-zone' "$root/files/usr/libexec/kobold-configure-firewall" || fail 'firewall zone services use the offline zone-removal API'
grep -Fq 'ExecStartPost=/usr/bin/touch /var/lib/kobold/firewall-default-applied' "$root/files/usr/lib/systemd/system/kobold-firewall-first-boot.service" || fail 'firewall reconciliation does not persist completion'
grep -Fq 'enable_if_present kobold-firewall-first-boot.service' "$root/files/usr/libexec/kobold-configure-services" || fail 'first-boot firewall reconciliation is not enabled'
grep -Fqx 'system-db:gdm' "$root/files/etc/dconf/profile/gdm" || fail 'GDM dconf profile missing'
grep -Fq "logo='/usr/share/kobold/branding/kobold-gdm-logo.png'" "$root/files/etc/dconf/db/gdm.d/01-kobold-logo" || fail 'GDM logo dconf source missing'
grep -Fq 'dconf update' "$root/build/60-desktop.sh" || fail 'GDM dconf database is not compiled during build'
[[ "$(<"$root/files/etc/hostname")" == kobold ]] || fail 'hostname is not kobold'
for size in 16 22 24 32 48 64 128 256 512; do [[ -s "$root/files/usr/share/icons/hicolor/${size}x${size}/apps/kobold.png" ]] || fail "missing icon $size"; done

# DNS design: Cloudflare fallback, never forced global DNS=.
grep -Fq 'FallbackDNS=1.1.1.1#one.one.one.one' "$root/files/etc/systemd/resolved.conf.d/60-kobold.conf" || fail 'Cloudflare fallback missing'
if grep -Eq '^DNS=' "$root/files/etc/systemd/resolved.conf.d/60-kobold.conf"; then fail 'global forced DNS would break private/captive networks'; fi

# ISO must directly install payload with Anaconda bootc; conversion switches are forbidden.
grep -Fq 'bootc --source-imgref=' "$root/iso/configure-installer.sh" || fail 'ISO direct bootc install missing'
if grep -RniE 'bootc[[:space:]]+switch|ostreecontainer' "$root/iso/Containerfile" "$root/iso/configure-installer.sh"; then fail 'ISO contains conversion/legacy install path'; fi

# No obvious embedded secret.
if grep -RniEI --exclude-dir=output --exclude='static-checks.sh' -- '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})' "$root"; then fail 'obvious secret detected'; fi

# JSON/YAML parse when Python modules are available.
python3 - <<'PY2' "$root" || fail 'JSON/YAML validation failed'
import json, pathlib, sys
r=pathlib.Path(sys.argv[1])
json.load(open(r/'renovate.json'))
try:
    import yaml
except Exception:
    raise SystemExit(0)
for p in (r/'.github/workflows').glob('*.yml'):
    yaml.safe_load(p.read_text())
yaml.safe_load((r/'iso/iso.yaml').read_text())
PY2

((failures == 0)) || exit 1
ok 'static checks passed'
