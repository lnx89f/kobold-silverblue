#!/usr/bin/env bash
set -euo pipefail

# Human-facing branding only; preserve Fedora/Silverblue compatibility identity.
cat >/etc/os-release <<'EOF'
NAME="Kobold"
PRETTY_NAME="Kobold 44 (Fedora Silverblue)"
ID=fedora
VERSION_ID=44
VERSION="44 (Fedora Silverblue)"
VERSION_CODENAME=""
PLATFORM_ID="platform:f44"
VARIANT="Silverblue"
VARIANT_ID=silverblue
LOGO=kobold
ANSI_COLOR="0;38;2;60;110;85"
HOME_URL="https://fedoraproject.org/atomic-desktops/silverblue/"
DOCUMENTATION_URL="https://docs.fedoraproject.org/en-US/fedora-silverblue/"
SUPPORT_URL="https://ask.fedoraproject.org/"
BUG_REPORT_URL="https://github.com/fedora-silverblue/issue-tracker/issues"
EOF

# Compile project GSettings defaults after branding assets are present.
glib-compile-schemas /usr/share/glib-2.0/schemas
dconf update

grep -Fqx 'ID=fedora' /etc/os-release
grep -Fqx 'VARIANT_ID=silverblue' /etc/os-release
grep -Fqx 'LOGO=kobold' /etc/os-release

# Niri is intentionally installed without a system/user config. Upstream defaults/user config own behavior.
rm -rf /etc/niri /usr/share/kobold/niri 2>/dev/null || :
