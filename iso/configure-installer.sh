#!/usr/bin/env bash
set -euo pipefail

: "${KOBOLD_PAYLOAD_IMAGE:?PAYLOAD_IMAGE build arg required}"
: "${KOBOLD_TARGET_IMAGE:?TARGET_IMAGE build arg required}"
[[ "$KOBOLD_PAYLOAD_IMAGE" != *' '* ]]
[[ "$KOBOLD_TARGET_IMAGE" != *' '* ]]

# Installer-only presentation and defaults. The installed OS identity comes from the payload.
mkdir -p /usr/share/anaconda
cat >/usr/share/anaconda/interactive-defaults.ks <<EOF
bootc --source-imgref="containers-storage:${KOBOLD_PAYLOAD_IMAGE}" --target-imgref="${KOBOLD_TARGET_IMAGE}"
EOF

# Reproduce the current image-builder bootc-generic-iso Anaconda contract.
if ! getent passwd install >/dev/null; then
  printf 'install:x:0:0:root:/root:/usr/libexec/anaconda/run-anaconda\n' >>/etc/passwd
  printf 'install::14438:0:99999:7:::\n' >>/etc/shadow
fi
passwd -d root

if [[ -e /usr/share/anaconda/list-harddrives-stub ]]; then
  mv /usr/share/anaconda/list-harddrives-stub /usr/bin/list-harddrives
fi
[[ -x /usr/bin/list-harddrives ]]

if [[ -d /etc/yum.repos.d ]]; then
  [[ ! -e /etc/anaconda.repos.d ]]
  mv /etc/yum.repos.d /etc/anaconda.repos.d
fi
[[ -d /etc/anaconda.repos.d ]]
ln -sfn /usr/lib/systemd/system/anaconda.target /etc/systemd/system/default.target
rm -f /usr/lib/systemd/system-generators/systemd-gpt-auto-generator

# Fedora's stock anaconda.service starts tmux directly.  In an Enforcing live
# system PID 1 (init_t) may not execute screen_exec_t, while the existing
# installer policy intentionally permits init_t -> install_t through an
# install_exec_t entrypoint.  Keep the upstream tmux workflow, but enter the
# existing installer domain first through a dedicated copy with a target-policy
# file-context rule.  This is installer bootstrap labeling, not a custom allow
# policy and not a relabel of the pre-labeled Kobold payload.
install -m 0755 /usr/bin/tmux /usr/libexec/anaconda/kobold-tmux
mkdir -p /etc/selinux/targeted/contexts/files
cat >>/etc/selinux/targeted/contexts/files/file_contexts.local <<'EOF'
/usr/libexec/anaconda/kobold-tmux -- system_u:object_r:install_exec_t:s0
EOF
sed -i 's#ExecStart=/usr/bin/tmux #ExecStart=/usr/libexec/anaconda/kobold-tmux #' \
  /usr/lib/systemd/system/anaconda.service \
  /usr/lib/systemd/system/anaconda-tmux@.service
grep -Fq 'ExecStart=/usr/libexec/anaconda/kobold-tmux ' /usr/lib/systemd/system/anaconda.service
grep -Fq 'ExecStart=/usr/libexec/anaconda/kobold-tmux ' /usr/lib/systemd/system/anaconda-tmux@.service

# Disable installer GeoIP language/timezone inference deterministically. Custom
# Anaconda configuration is loaded after the Fedora profile and therefore wins.
mkdir -p /etc/anaconda/conf.d
cat >/etc/anaconda/conf.d/90-kobold.conf <<'EOF'
[Localization]
use_geolocation = False
EOF

# Keep install interactive: no clearpart/autopart/user/password directives are embedded here.
# Disable installer connectivity/user surprises where unit names are present.
systemctl disable rpm-ostree-countme.service 2>/dev/null || :
systemctl disable flatpak-preinstall.service 2>/dev/null || :
systemctl disable kobold-flatpak-preinstall.service 2>/dev/null || :

# Installer live GNOME branding.
mkdir -p /usr/share/glib-2.0/schemas
cat >/usr/share/glib-2.0/schemas/99_kobold_installer.gschema.override <<'EOF'
[org.gnome.desktop.session]
idle-delay=uint32 0

[org.gnome.settings-daemon.plugins.power]
sleep-inactive-ac-type='nothing'
sleep-inactive-battery-type='nothing'
sleep-inactive-ac-timeout=0
sleep-inactive-battery-timeout=0
EOF
glib-compile-schemas /usr/share/glib-2.0/schemas
