# AGENTS.md — Kobold

## Authority

Read `KOBOLD-SPEC.md` before changing the project. Authority order:

1. `KOBOLD-SPEC.md`
2. `AGENTS.md`
3. `docs/`
4. tests/invariants
5. implementation

If implementation conflicts with the specification, fix the implementation. Do not silently rewrite the specification to match a failure. Architectural changes must be reported before implementation.

## Mission

Kobold is a personal Fedora Silverblue/Atomic workstation image, not an independent distribution. It intentionally adds practical hardening, privacy policy, laptop tuning, a minimal developer host, deterministic builds, direct-install ISO delivery and extensive aesthetic branding while preserving Fedora as the OS/security upstream.

## Base and inheritance

- Base only on `quay.io/fedora/fedora-silverblue:44` by immutable digest.
- Do not use `quay.io/fedora-ostree-desktops/silverblue` as the Kobold base.
- Do not switch to `fedora-bootc` and reconstruct Silverblue manually.
- Do not use Bluefin, Bluefin DX, Secureblue, Aurora, Finpilot, UBlue or `projectbluefin/common` as runtime inheritance.
- Bluefin/Finpilot may be inspected as engineering references only.
- Preserve Fedora kernel, shim/Secure Boot chain, SELinux base policy, GNOME, NetworkManager, firewalld, Podman and libvirt unless the spec explicitly says otherwise.

## Repository trust

- Remove `fedora-workstation-repositories` and `fedora-third-party` package-aware.
- Do not allow Google Chrome, RPM Fusion or COPR opt-in repo files to persist.
- Do not solve repo gates by expanding the allowlist.
- Final `.repo` files must be RPM-owned by `fedora-repos` or `fedora-repos-archive`; never trust a filename prefix as the repository allowlist.
- The Microsoft VS Code repository is permitted only during image composition and must not persist in the final image.
- Flathub is the permitted Flatpak remote.
- Unexpected repository state is a build failure.

## Security

- SELinux must be Enforcing at runtime. Never disable or globally set permissive to solve a problem.
- Preserve documented Kobold sysctl/kernel/network hardening unless a demonstrated compatibility issue requires review.
- Do not add random hardening checklist settings. Evaluate security benefit and workstation cost.
- Default firewalld policy exposes no inbound host service. Do not silently open ports for development tools.
- SSH server remains absent. OpenSSH client is allowed.
- GeoClue/location, unsolicited discovery/sharing and Fedora count-me behavior remain disabled/absent as specified.
- Do not embed credentials, Wi-Fi profiles, SSH keys, tokens, registry auth or personal state.

## Tuning

- Low temperature, battery efficiency and responsiveness are first-class requirements.
- Use the documented TuneD/tuned-ppd design; do not replace it with generic Fedora defaults simply to reduce configuration.
- Do not reintroduce alpha-era `vm.swappiness=150`, custom watermark/dirty-page/ZRAM tuning, disabled Wi-Fi power saving or disabled HDA audio power saving without measurement and spec change.
- Do not globally force USB autosuspend.
- Hardware-specific workarounds must be clearly scoped instead of becoming universal policy.

## Desktop and applications

- GNOME/Wayland is primary.
- Niri remains installed, but Kobold provides no user Niri config.
- Flathub is configured, but Firefox is user-selected and must not be automatically preinstalled.
- GNOME Software remains absent.
- VS Code remains the official Microsoft RPM.
- Keep the justified host CLI/admin baseline, including Trivy, Lynis, btop, storage/network diagnostics and rootless Podman helpers; toolchains and application stacks belong in Toolbx/Distrobox/Podman where practical.
- Podman is rootless-oriented; the system rootful `podman.socket` remains masked. Do not add Docker Engine, docker-compose, `podman-docker` or `podman-compose`.
- QEMU/KVM + modular libvirt remain available; do not create or autostart VMs in the image.

## Localization and branding

- Preserve Fedora Silverblue's native localization and input-method coverage; do not prune languages, `langpacks-*`, glibc language packs or IBus engines by locale.
- Do not force a Kobold-wide default locale, keyboard or timezone. The interactive installer/user selection owns those choices.
- Never blindly delete RPM-owned `/usr/share/locale` trees. Installer geolocation remains disabled.
- Kobold branding may cover wallpaper, lock screen, GDM, icons and human-facing OS presentation while retaining technical Fedora/Silverblue compatibility identity.

## Networking and DNS

- Preserve NetworkManager + systemd-resolved integration.
- Cloudflare is fallback DNS, not a globally forced resolver.
- Do not break DHCP, captive networks, VPN DNS or split DNS.
- Preserve documented LLMNR/mDNS/privacy/MAC policies unless a real compatibility issue is demonstrated.

## Build discipline

- Shell scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Builds must fail on unexpected state. Never add `|| true` merely to make a required step pass.
- Do not delete tests, weaken invariants or widen allowlists to accommodate an unexpected build result.
- Do not use `curl | sh` or equivalent remote execution. Verify remote keys/artifacts where supported.
- Keep changes scoped and deterministic.
- `/usr` is image-owned; `/etc` follows bootc merge/persistence semantics; `/var` and `/home` are mutable runtime state. Do not move paths to `/var` without a concrete reason.

## ISO

- ISO must install the Kobold payload directly.
- Do not install Fedora/Bluefin first and then convert using `bootc switch`.
- Treat the validated Kobold OCI payload and the Fedora-derived Anaconda live image as separate artifacts. The installer image is never the installed payload.
- Use the current `image-builder` CLI and `bootc-generic-iso`; do not maintain a second legacy builder path.
- Keep SELinux Enforcing in the live installer. Generate live SquashFS labels from the installer image's own Fedora policy, never from the host policy or the Kobold payload.
- A successful ISO build is not final validation; clean-install acceptance in `tests/iso-acceptance.md` is required for a release candidate.

## Updates and releases

- Fedora 44 base is digest-pinned. Major Fedora upgrades are explicit project changes.
- `testing` is built first. `stable` promotion reuses the exact validated digest; do not rebuild a different artifact for stable.
- Do not promote stable automatically just because a build succeeds.
- Kobold OCI images are signed keylessly with GitHub OIDC and receive provenance attestations as defined by workflows.

## Required validation

For source changes run at minimum:

```bash
./tests/static-checks.sh
```

For a full candidate, complete all applicable stages:

1. static checks;
2. Fedora base gate;
3. OCI build;
4. image invariants;
5. `bootc container lint --fatal-warnings`;
6. QCOW2/runtime smoke test when available;
7. ISO build;
8. clean ISO installation;
9. `tests/iso-acceptance.md`;
10. identify candidate by immutable digest.

Never claim runtime or ISO validation when only source/static checks ran. Report changed files, root causes, commands/tests, remaining warnings and untested areas.
