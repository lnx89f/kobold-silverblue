# Kobold

Kobold is a personal, opinionated **Fedora Silverblue workstation image**. It keeps Fedora as the security and operating-system upstream while making a controlled set of decisions for hardening, privacy, thermal/battery tuning, containers, virtualization, minimal applications and branding.

It is intentionally not a new distribution, does not replace Fedora's kernel or SELinux policies, and does not inherit Bluefin/UBlue runtime layers. Bluefin and Finpilot are engineering references. The base is the Fedora-published Silverblue 44 bootable OCI from `quay.io/fedora/fedora-silverblue`, pinned by digest. Kobold deliberately does not use the separate `fedora-ostree-desktops` SIG stream as its base.

## What is different from Silverblue

- stricter inbound firewall (`drop`, no default openings)
- additional kernel/network hardening for a normal developer workstation
- SELinux Enforcing as a tested invariant
- no SSH server, printer daemon, Avahi discovery, ModemManager, GNOME remote desktop/user sharing or automatic connectivity probing
- location disabled and GeoClue activation blocked
- privacy-oriented NetworkManager defaults and Cloudflare fallback DNS with opportunistic DoT
- TuneD policy focused on cool/efficient laptop operation without USB autosuspend
- rootless Podman, modular libvirt/QEMU/KVM
- official Microsoft VS Code RPM
- Flathub configured; Firefox is installed manually when desired; no GNOME Software
- Dev/DevSecOps CLI includes Trivy, Lynis and focused hardware diagnostics
- GNOME plus Niri (Niri ships without a Kobold user config)
- Fedora Silverblue native language/localization coverage; installer-selected locale
- Kobold wallpaper, icons, GDM logo and OS presentation while preserving Fedora/Silverblue compatibility identity
- package-aware removal of Fedora Workstation third-party opt-in repositories
- signed testing/stable OCI release workflow and a direct-bootc ISO path

Read `KOBOLD-SPEC.md` before changing the build. Every nontrivial change should have a reason and an invariant/test.

## Local checks

```bash
./tests/static-checks.sh
sudo podman build --format oci -t localhost/kobold:dev .
./tests/image-invariants.sh localhost/kobold:dev
```

For a runtime deployment:

```bash
pinguim doctor
sudo bootc status
```

Kobold intentionally does not enable unattended bootc reboots. Update when desired with the normal bootc workflow after reviewing the published stable image.

For ISO work, the validated Kobold OCI and the Fedora-derived live installer are separate inputs. Build them with `iso/build-installer.sh` and `iso/build-iso.sh`; the unified Image Builder `bootc-generic-iso` flow embeds the Kobold payload for direct Anaconda installation. See `docs/ISO.md` and complete `tests/iso-acceptance.md` before treating an ISO as validated.

## Repository layout

- `Containerfile` — image composition
- `build/` — deterministic build stages
- `files/` — configuration copied into the image
- `KOBOLD-SPEC.md` — source of truth for design/policy
- `docs/` — architecture, security, tuning, network, update and ISO notes
- `tests/` — static, image and clean-install acceptance checks
- `.github/workflows/` — validate, publish testing, promote stable and build ISO
- `iso/` — separate Fedora-derived installer environment and unified Image Builder scripts; it installs the Kobold payload directly
