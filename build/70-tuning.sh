#!/usr/bin/env bash
set -euo pipefail

# TuneD owns power policy. Persist a conservative interactive default.
mkdir -p /etc/tuned
printf 'balanced\n' >/etc/tuned/active_profile

grep -Fqx 'include=balanced-battery' /etc/tuned/profiles/kobold-powersave/tuned.conf
grep -Fqx 'power-saver=kobold-powersave' /etc/tuned/ppd.conf
grep -Fqx 'wifi.powersave=3' /etc/NetworkManager/conf.d/20-kobold-privacy.conf

# Explicitly ensure alpha-era power/VM overrides are gone.
! test -e /etc/systemd/zram-generator.conf
! grep -Rqs 'snd_hda_intel power_save=0' /etc/modprobe.d /usr/lib/modprobe.d 2>/dev/null
! grep -Rqs 'wifi.powersave=2' /etc/NetworkManager/conf.d 2>/dev/null
! grep -Rqs 'vm.swappiness = 150' /etc/sysctl.d /usr/lib/sysctl.d 2>/dev/null
