# Kobold

**Kobold** is a Fedora Silverblue bootc workstation image focused on minimalism, security, efficiency, and Dev/DevSecOps workflows.

It keeps Fedora Silverblue as its technical foundation while defining a curated host configuration, security policy, development environment, and desktop defaults through a reproducible bootable container image.

Kobold is not an independent Linux distribution. It remains Fedora-based and preserves Fedora's kernel, Secure Boot integration, SELinux, Atomic Desktop model, and bootc-compatible system architecture.

## Goals

Kobold is designed around a small set of principles:

- Fedora Silverblue as the base system
- Atomic, image-based system management with `bootc`
- SELinux Enforcing
- Curated GNOME desktop
- Predictable and reproducible host configuration
- Rootless containers by default
- Minimal host package footprint
- Development tools isolated from the host whenever practical
- No Docker daemon
- No Homebrew
- No RPM Fusion
- No third-party COPR repositories
- No unnecessary network-facing services
- Fedora-native technologies preferred whenever possible

## Host environment

Kobold includes a curated workstation environment with:

- GNOME
- Podman rootless
- Buildah
- Skopeo
- Toolbx
- Distrobox
- Quadlet support
- QEMU/KVM
- libvirt
- virt-manager
- Visual Studio Code from Microsoft's official RPM repository
- Git
- GitHub CLI
- Trivy
- Lynis
- Common CLI, networking, and hardware diagnostic tools

A lightweight Niri environment is also available without replacing GNOME as the primary desktop.

## Security

Kobold preserves Fedora's native security model and adds conservative workstation hardening.

The system uses:

- SELinux Enforcing
- Fedora Secure Boot stack
- firewalld with a restrictive host policy
- Hardened kernel and filesystem sysctl defaults
- Restricted kernel information exposure
- Restricted ptrace and performance interfaces
- Disabled unprivileged BPF
- Network privacy defaults
- Randomized Wi-Fi scanning MAC addresses
- Stable per-network Wi-Fi MAC identities
- LLMNR and mDNS disabled
- systemd-resolved
- Opportunistic DNS-over-TLS
- Cloudflare only as fallback DNS

The hardening policy is designed to preserve normal desktop use, rootless containers, virtualization, and development workflows.

## Applications

Kobold intentionally keeps the base desktop small.

Flathub is configured, but Flatpak applications are not automatically installed.

For example, Firefox can be installed with:

```bash
flatpak install flathub org.mozilla.firefox
```

Additional desktop applications should preferably be installed through Flatpak.

Development toolchains, SDKs, language runtimes, and project-specific dependencies should preferably live in Toolbx, Distrobox, or rootless containers instead of being added to the host image.

# Using the project

## Requirements

A Fedora-based system with the following tools is recommended:

```text
podman
git
sha256sum
```

Root privileges are required for operations that use the root Podman container storage.

## Clone the repository

```bash
git clone https://github.com/lnx89f/kobold-silverblue.git
cd kobold-silverblue
```

## Validate the source

Verify the source manifest:

```bash
sha256sum -c SOURCE-SHA256SUMS
```

Run the static project checks:

```bash
./tests/static-checks.sh
```

Both checks should complete successfully before building the image.

# Local build

Build the Kobold bootc image locally:

```bash
sudo podman build \
  --format oci \
  --pull=never \
  -t localhost/kobold:dev \
  .
```

Inspect the resulting image:

```bash
sudo podman image inspect localhost/kobold:dev
```

Run the image invariants:

```bash
sudo podman run --rm \
  localhost/kobold:dev \
  /usr/libexec/kobold-image-invariants
```

Run the bootc container lint:

```bash
sudo podman run --rm --privileged \
  --entrypoint bootc \
  localhost/kobold:dev \
  container lint --fatal-warnings
```

## Rebuild

After modifying the source, update `SOURCE-SHA256SUMS`, validate the repository again, and rebuild the image.

Verify the repository first:

```bash
sha256sum -c SOURCE-SHA256SUMS
./tests/static-checks.sh
```

Then rebuild:

```bash
sudo podman build \
  --format oci \
  --pull=never \
  -t localhost/kobold:dev \
  .
```

Podman will reuse valid cached layers and rebuild only the layers affected by source changes.

For a completely clean local rebuild:

```bash
sudo podman build \
  --format oci \
  --no-cache \
  --pull=never \
  -t localhost/kobold:dev \
  .
```

# GitHub Actions

The repository contains GitHub Actions workflows for validation and bootc image publication.

The intended workflow is:

```text
source
  ↓
validation
  ↓
OCI build
  ↓
GHCR testing image
  ↓
validation
  ↓
stable promotion
```

Changes pushed to the repository are validated by GitHub Actions.

The testing image is published to:

```text
ghcr.io/lnx89f/kobold-silverblue:testing
```

The stable image is published to:

```text
ghcr.io/lnx89f/kobold-silverblue:stable
```

The stable channel is intended to reference an already validated image rather than rebuilding a different image during promotion.

# Installing Kobold

The current deployment method is to start from a clean Fedora Silverblue installation and switch its bootc image source to Kobold.

## 1. Install Fedora Silverblue

Install Fedora Silverblue normally.

After the first boot, update the system and reboot if necessary.

Check the current deployment:

```bash
bootc status
```

## 2. Switch to Kobold testing

To switch the system to the Kobold testing image:

```bash
sudo bootc switch \
  ghcr.io/lnx89f/kobold-silverblue:testing
```

When the operation completes, reboot:

```bash
systemctl reboot
```

## 3. Verify Kobold

After rebooting:

```bash
bootc status
```

Verify SELinux:

```bash
getenforce
```

Expected result:

```text
Enforcing
```

Check systemd failures:

```bash
systemctl --failed
```

Run the Kobold diagnostic:

```bash
pinguim doctor
```

## Switching to stable

Once a stable image is available:

```bash
sudo bootc switch \
  ghcr.io/lnx89f/kobold-silverblue:stable
```

Then reboot:

```bash
systemctl reboot
```

# Updating Kobold

Kobold system updates are delivered as new bootc images.

Check for updates:

```bash
sudo bootc upgrade --check
```

Stage an available update:

```bash
sudo bootc upgrade
```

Then reboot:

```bash
systemctl reboot
```

The previous deployment remains available for rollback according to the normal bootc deployment model.

Check the current deployment at any time with:

```bash
bootc status
```

# Rollback

If a newly deployed image causes problems, inspect the current deployments with:

```bash
bootc status
```

Then use the appropriate bootc rollback workflow for the installed deployment.

# Development environments

Kobold keeps development toolchains out of the host whenever practical.

## Toolbx

Create a development container:

```bash
toolbox create
```

Enter it:

```bash
toolbox enter
```

## Distrobox

Create an environment:

```bash
distrobox create --name dev
```

Enter it:

```bash
distrobox enter dev
```

# Containers

Kobold is designed around rootless Podman.

Example:

```bash
podman run --rm \
  docker.io/library/alpine:latest \
  cat /etc/os-release
```

Persistent containerized services should preferably use rootless Podman Quadlets.

Docker, Docker Compose, and Docker-compatible host shims are intentionally not part of the Kobold host environment.

# Virtualization

Kobold includes QEMU/KVM, libvirt, and virt-manager.

Launch virt-manager with:

```bash
virt-manager
```

Virtual machines are intended to run on demand rather than through unnecessary VM autostart services.

# Project structure

```text
Containerfile
    Main Kobold bootc image definition.

build/
    Ordered image build stages.

files/
    Files installed into the image.

ci/
    Continuous integration validation helpers.

tests/
    Static, image, and runtime validation.

docs/
    Technical project documentation.

KOBOLD-SPEC.md
    Authoritative Kobold system specification.

AGENTS.md
    Repository implementation and maintenance rules.

SOURCE-SHA256SUMS
    Source integrity manifest.
```

The project authority order is:

```text
KOBOLD-SPEC.md
    ↓
AGENTS.md
    ↓
docs/
    ↓
tests/
    ↓
implementation
```

# Documentation

Additional documentation is available under `docs/`:

- `ARCHITECTURE.md`
- `SECURITY.md`
- `NETWORK.md`
- `TUNING.md`
- `UPDATE.md`
- `RECOVERY.md`
- `SOURCE_REUSE.md`

# Fedora base

Kobold is built from Fedora Silverblue.

Fedora remains the operating system identity and upstream platform. Kobold defines a reproducible workstation configuration on top of that base rather than replacing Fedora with an independent distribution.
