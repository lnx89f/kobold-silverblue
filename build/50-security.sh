#!/usr/bin/env bash
set -euo pipefail

# Static sanity for project-owned policy files. Do not apply sysctls while
# building the container: sysctl targets the build host/container kernel,
# not the future booted system. Runtime acceptance verifies effective values.
awk '
  /^[[:space:]]*($|#)/ { next }
  /^[[:space:]]*[A-Za-z0-9_.]+[[:space:]]*=[[:space:]]*-?[0-9]+[[:space:]]*$/ { next }
  { print "Invalid sysctl line: " $0 > "/dev/stderr"; bad=1 }
  END { exit bad ? 1 : 0 }
' /etc/sysctl.d/60-kobold-security.conf
systemd-analyze verify /usr/lib/systemd/system/kobold-firewall-first-boot.service

# No SSH daemon is part of the image.
! rpm -q openssh-server >/dev/null 2>&1

# Root account must not have a usable password and no human account belongs in an image.
root_hash=$(getent shadow root | cut -d: -f2)
[[ "$root_hash" == '!'* || "$root_hash" == '*'* ]]
! awk -F: '$3 >= 1000 && $3 < 65534 { found=1 } END { exit found ? 0 : 1 }' /etc/passwd

# Never bake machine/user credentials into a reusable image.
! find /etc/ssh /root /home -xdev -type f \
  \( -name 'ssh_host_*' -o -name authorized_keys -o -name 'id_*' \) \
  -print -quit 2>/dev/null | grep -q .
! find /etc/NetworkManager/system-connections /root /home -xdev -type f \
  \( -name '*.nmconnection' -o -name auth.json -o -name hosts.yml \) \
  -print -quit 2>/dev/null | grep -q .
