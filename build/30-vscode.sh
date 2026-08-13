#!/usr/bin/env bash
set -euo pipefail

key=/tmp/microsoft.asc
repo=/etc/yum.repos.d/kobold-vscode-build.repo
gnupg_home=$(mktemp -d /tmp/kobold-gnupg.XXXXXX)
chmod 0700 "$gnupg_home"
cleanup() { rm -f "$key" "$repo"; rm -rf "$gnupg_home"; }
trap cleanup EXIT

curl --fail --location --proto '=https' --tlsv1.2 \
  --retry 5 --retry-all-errors \
  https://packages.microsoft.com/keys/microsoft.asc -o "$key"

fingerprint=$(gpg --homedir "$gnupg_home" --show-keys --with-colons "$key" | awk -F: '$1=="fpr" {print $10; exit}')
[[ "$fingerprint" == 'BC528686B50D79E339D3721CEB3E94ADBE1229CF' ]] || {
  printf 'Unexpected Microsoft signing-key fingerprint: %s\n' "$fingerprint" >&2
  exit 1
}
rpm --import "$key"

cat >"$repo" <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

dnf5 -y --setopt=install_weak_deps=False install code
rpm -q --qf '%{VENDOR}\n' code | grep -Fqx 'Microsoft Corporation'
