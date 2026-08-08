# Kobold Silverblue

Kobold is a personal Fedora Silverblue bootc workstation focused on minimalism, security, efficiency, and Dev/DevSecOps workflows.

## Status

**Design / pre-build.** No installable Kobold image is published yet.

## Architecture

Kobold is based directly on the official Fedora Silverblue image. Finpilot may be used only as build/CI scaffolding where useful; Kobold does not use Bluefin as its runtime base and does not depend on Universal Blue userland components.

```text
Fedora Silverblue
      ↓
Finpilot / build & CI scaffolding
      ↓
Kobold
```

## Goals

- Minimal GNOME workstation with optional Niri session.
- SELinux enforcing and hardened defaults.
- Firewalld with a closed-by-default inbound policy.
- Podman rootless + Distrobox.
- QEMU/KVM + libvirt + virt-manager.
- Official Microsoft Visual Studio Code RPM.
- Conservative power and thermal tuning validated on the target hardware.
- Flatpak-first desktop applications through GNOME Software.
- Image-based updates through bootc.
- Controlled `testing` → `stable` promotion, targeting roughly 14-day stable releases with an emergency security promotion path.
- No Bluefin runtime, Homebrew, Docker, RPM Fusion, or custom branding.

## Default desktop applications

Kobold intends to keep only a small core set in the host image:

- Nautilus
- GNOME Software
- Ptyxis
- GNOME Text Editor
- Loupe
- GNOME Calculator
- GNOME Disks
- Visual Studio Code (official Microsoft RPM)

Firefox and other desktop applications are intended to be installed manually through GNOME Software / Flatpak.

## Development model

The host provides the stable workstation substrate. Project-specific toolchains should normally live in Distrobox, Podman containers, or virtual machines instead of being layered into the host image.

## Technical specification

See [`CODEX.md`](CODEX.md) for the current implementation specification, validation rules, release model, and constraints.

## Source projects

During implementation, the local Pinguim and Akatsuki repositories are used as engineering references for previously validated configuration and testing patterns. Kobold is a new project and is not a rebrand of either one.

## License

Not selected yet.
