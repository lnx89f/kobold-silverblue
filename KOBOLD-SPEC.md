# Kobold specification

Kobold is an opinionated Fedora Silverblue workstation image, not an independent Linux distribution. Fedora remains the operating-system and security-policy upstream. Kobold defines a deliberately small set of workstation policies that are versioned, built, tested and signed as an OCI image.

## Design invariants

1. **Base:** Fedora-published Silverblue 44 bootable OCI (`quay.io/fedora/fedora-silverblue`), pinned by digest. Kobold does not use the separate `fedora-ostree-desktops` SIG stream as its base. Fedora's public Silverblue release remains the upstream/canonical operating-system source; a Fedora major transition is always an explicit project change.
2. **Identity:** `ID=fedora` and `VARIANT_ID=silverblue` remain intact. `NAME`, `PRETTY_NAME`, logo, wallpaper and GDM presentation may be branded Kobold. GDM branding is applied through its dedicated system dconf database, not a user-session preference.
3. **Security:** SELinux must be Enforcing. No custom SELinux policy is shipped unless a concrete requirement appears.
4. **Network exposure:** no inbound host service is open by default. firewalld default zone is `drop` and contains no default openings.
5. **Remote access:** OpenSSH server is absent. OpenSSH client is installed.
6. **Containers:** Podman is the container engine. Rootful system `podman.socket` is masked. Docker compatibility packages are absent. Rootless Podman is supported.
7. **Virtualization:** QEMU/KVM and modular libvirt socket activation are available; no VM is created or configured for autostart by the image.
8. **Desktop:** GNOME/Wayland is the primary desktop. Niri is installed but Kobold does not provide a Niri user configuration.
9. **GUI applications:** no GNOME Software. Flathub is configured, but Firefox is not automatically provisioned; install `org.mozilla.firefox` manually when desired. Minimal native GNOME utilities remain.
10. **Development:** VS Code is the official Microsoft RPM. Small host CLI/admin tools remain native RPMs, including Git/GitHub utilities, `btop`, Trivy, Lynis, SMART/NVMe/network diagnostics and the rootless Podman helpers. Toolchains, SDKs and application stacks belong in Toolbx/Distrobox/Podman whenever practical.
10a. **RPM repositories:** Final RPM repository files must be package-owned by Fedora repository packages (`fedora-repos` or `fedora-repos-archive`); a Fedora-looking filename alone is not sufficient. `fedora-workstation-repositories` and `fedora-third-party` are removed package-aware; Google Chrome, RPM Fusion and COPR opt-in repository files must not persist. The Microsoft VS Code repository is build-time only and must not persist in the final image. Flathub is the allowed Flatpak remote.
11. **Language:** Kobold preserves Fedora Silverblue's native localization coverage. It does not prune glibc language packs, `langpacks-*`, IBus engines or package translations by locale, and it does not force a project-wide system locale. The interactive installer owns the user's language, keyboard and timezone choices. Installer geolocation remains disabled for privacy/determinism.
12. **Privacy:** automatic connectivity probing, LLMNR, mDNS, location service activation, Fedora count-me telemetry, printer discovery and unsolicited remote desktop/user sharing are disabled or absent.
13. **DNS:** systemd-resolved is used; network-provided per-link DNS remains allowed for compatibility. DNS-over-TLS is opportunistic. Cloudflare is the explicit fallback resolver, not a forced resolver that would break captive portals/private DNS.
14. **Bluetooth:** Bluetooth stack remains functional but the radio defaults to off after boot.
15. **Power:** TuneD/tuned-ppd is the policy engine. Default is balanced; battery maps to `balanced-battery`; Kobold provides a stricter power-saver profile without USB autosuspend. Wi-Fi power saving is enabled.
16. **USB:** Kobold does not force USB autosuspend.
17. **Memory:** Fedora's ZRAM defaults are retained. Kobold does not carry alpha-era VM/ZRAM tuning without measured evidence.
18. **Updates:** no unattended bootc reboot. Image publication uses `testing` and `stable` channels. Renovate proposes pinned Silverblue digest updates. Stable promotion occurs twice monthly or manually for urgent fixes.
19. **Supply chain:** CI accepts only `quay.io/fedora/fedora-silverblue:44@sha256:...`, pulls that immutable object and verifies Silverblue/bootc identity before building. Kobold does not claim an upstream Cosign verification policy that Fedora has not documented for this stream. Kobold testing/stable images are signed keylessly with GitHub OIDC and receive provenance attestations. Stable promotion copies an already-built verified digest; it does not rebuild.
20. **ISO:** installer must install the Kobold payload directly through Anaconda's `bootc` command. It must not install another OS and convert it with `bootc switch`. The validated Kobold OCI payload and the Fedora-derived live installer image are separate artifacts: `installer image -> image-builder bootc-generic-iso -> ISO -> direct Kobold installation`. SELinux remains Enforcing in the installer, payload and installed system. The live SquashFS is labeled from the installer image's own Fedora policy; container-storage mount labels must never become live OS labels. Installer scratch placed on the target must be released before the target becomes read-only; `--skip-finalize` may defer only bootc's filesystem trim/remount/freeze sequence, which the installer wrapper must then reproduce for root and a separate `/boot` after successful deployment and cleanup. The wrapper must identify Anaconda's `/mnt/sysimage` physical-root argument independently of argv ordering so graphical and Kickstart paths cannot bypass the scratch/finalization adapter.

## Security controls intentionally stricter than Fedora defaults

The kernel/network sysctl policy is kept in one auditable file. It blocks kernel address disclosure, unprivileged dmesg, arbitrary cross-process ptrace, kexec after policy application and unprivileged BPF; hardens common filesystem link/FIFO attacks; rejects IP redirects/source routes; enables SYN cookies and loose reverse-path filtering. It deliberately does **not** disable user namespaces, IPv6, IP forwarding globally, io_uring, USB, or other facilities required by Flatpak, rootless containers, libvirt or normal workstation use.

## Hardening trade-offs

- `kernel.kexec_load_disabled=1` prevents kexec/kdump loading until reboot. Kobold accepts this because it is a workstation, not a kernel-debugging host.
- `kernel.unprivileged_bpf_disabled=1` prevents unprivileged BPF. Privileged administration is still possible, while ordinary web/Podman development does not depend on unprivileged eBPF.
- `kernel.yama.ptrace_scope=1` permits normal parent/child debugger workflows but blocks arbitrary same-user process attachment.
- Persistent core dumps are disabled to reduce the chance of secrets being left in crash artifacts. Journal crash metadata remains available.
- Firewalld `drop` means LAN-facing development servers require an explicit rule; localhost development is unaffected.

## Definition of done

A release candidate is acceptable only when source static checks pass, the OCI builds, `/usr/libexec/kobold-image-invariants --build` passes, `bootc container lint --fatal-warnings` passes, the resulting digest is signed, and one clean graphical interactive ISO installation into an empty VM/disk passes `tests/iso-acceptance.md`. Automated Kickstart installation is supplementary and does not replace this shipped GUI path. ISO acceptance gates BIOS live boot before UEFI and installation; both the live and installed systems must report SELinux Enforcing, have clean kernel command lines, and have no structural SELinux denials preventing systemd or Anaconda. Runtime acceptance includes installer-selected locale/keyboard/timezone behavior, Flathub availability without automatic Firefox provisioning, Bluetooth-off default with functional GNOME toggle, networking/DNS, rootless Podman, libvirt, TuneD profile switching, firewall state, audit tooling availability and bootc status.
