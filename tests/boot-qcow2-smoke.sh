#!/usr/bin/env bash
set -euo pipefail
qcow=${1:?Usage: boot-qcow2-smoke.sh path/to/image.qcow2}
command -v qemu-system-x86_64 >/dev/null || { echo 'qemu-system-x86_64 required' >&2; exit 1; }
[[ -f "$qcow" ]] || { echo "not found: $qcow" >&2; exit 1; }

echo 'Manual smoke boot: close QEMU after verifying GDM, locale and basic boot.'
exec qemu-system-x86_64 \
  -enable-kvm -cpu host -smp 4 -m 4096 \
  -drive "file=$qcow,if=virtio,format=qcow2" \
  -device virtio-vga-gl -display gtk,gl=on \
  -nic user,model=virtio-net-pci
