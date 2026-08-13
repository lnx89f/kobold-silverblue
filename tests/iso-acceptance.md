# Kobold ISO clean-install acceptance

Run this once for the release-candidate ISO on an empty VM/disk. Do not validate by switching an existing Silverblue/Bluefin deployment. Stop at the first gate failure: do not proceed from BIOS to UEFI, or from UEFI to installation, while a prior gate is failing.

1. Boot the ISO in legacy BIOS mode. The installer UI must load and remain usable.
2. In the BIOS live environment, `getenforce` must return `Enforcing`.
3. In the BIOS live environment, `/proc/cmdline` must contain neither a permissive SELinux argument nor a SELinux-disable argument.
4. Inspect the live journal/audit log. There must be no structural AVC series preventing PID 1, systemd units, `/dev`, `/run` or Anaconda from operating. Ordinary isolated denials must be recorded and reviewed, not hidden with a generated broad policy.
5. Boot the same ISO in normal UEFI mode. The installer UI must load and remain usable; repeat the live SELinux and command-line checks.
6. When the infrastructure exposes Secure Boot with Fedora's normal shim/kernel chain, repeat the UEFI boot with Secure Boot enabled and record the result separately.
7. Confirm the graphical installer exposes Fedora/Anaconda's normal language selection and is not forced to pt-BR/English-only policy.
8. Install through the graphical interactive Anaconda path to an empty virtual disk using the intended Btrfs layout. If disk encryption is part of the intended real install, test that exact choice here. An automated/test-only Kickstart installation may be run as an additional smoke test, but it does not satisfy this graphical release gate.
9. Reboot from disk, create/login to the user, and run `pinguim doctor`.
10. `getenforce` => `Enforcing`.
11. `/proc/cmdline` must contain neither a permissive SELinux argument nor a SELinux-disable argument. Inspect persistent BLS/bootloader entries and require the same.
12. `bootc status` points directly at the selected Kobold registry image/tag; no Bluefin/Akatsuki/Pinguim deployment remains.
13. After choosing language/keyboard/timezone in the installer, confirm `localectl status` and `locale` reflect those choices and that the installed system is not constrained to a Kobold-specific PT/EN locale subset.
14. `firewall-cmd --get-default-zone` => `drop`; `firewall-cmd --permanent --zone=drop --list-services` and `firewall-cmd --permanent --zone=drop --list-ports` both return empty. `rpm -q openssh-server` reports it absent and `systemctl status sshd.service` reports that the unit does not exist. The OpenSSH client may remain installed.
15. Wi-Fi connects normally; reconnect/reboot works. Test at least one normal WPA2/WPA3 network.
16. `resolvectl status` works. Normal DNS resolves. Network-supplied DNS may appear per-link; Cloudflare appears as fallback. Captive/private DNS must not be broken by a forced global resolver.
17. Bluetooth starts powered off; GNOME quick-settings can turn it on, pair/use it, and turn it off.
18. GNOME GDM shows Kobold logo; desktop wallpaper/icon branding is present.
19. Confirm the system Flathub descriptor exists, `/usr/share/flatpak/preinstall.d/kobold.preinstall` and `kobold-flatpak-preinstall.service` are absent, and no Firefox RPM or GNOME Software is installed. Firefox is a post-install user choice (`flatpak install flathub org.mozilla.firefox`), not an ISO acceptance gate.
20. VS Code is installed and `rpm -q --qf '%{VENDOR}\n' code` returns Microsoft Corporation.
21. `podman info` works rootless for the user; system `podman.socket` is not enabled.
22. Toolbx/Distrobox can create a container.
23. `/dev/kvm` is usable when VM exposes virtualization; virt-manager starts and libvirt modular sockets activate on demand.
24. GNOME power-profile switcher works through tuned-ppd. Test balanced and power-saver; `tuned-adm active` follows the selection. No USB input/storage device unexpectedly autosuspends due to Kobold policy.
25. Niri appears as an available session and no Kobold `/etc/niri/config.kdl` is imposed.
26. Reboot twice; the above policy remains stable and idle memory/temperature settle normally.

Release acceptance is **PASS** only when all relevant checks pass. Record hardware/VM config, image digest and ISO SHA256 with the result.
