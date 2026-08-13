# ISO strategy

The ISO is a delivery mechanism for the Kobold OCI image. It must not install Silverblue/Bluefin first and then convert that system.

The single supported architecture is:

`installer image -> image-builder bootc-generic-iso -> ISO -> direct Kobold installation`

The Kobold OCI payload is not the installer live image. `iso/Containerfile` creates a dedicated Fedora bootc/Anaconda environment with kernel, initramfs, shim, GRUB and the tools required by the current `bootc-generic-iso` contract. Image Builder receives that image through `--bootc-ref` and receives the already-validated Kobold OCI separately through `--bootc-installer-payload-ref`. Anaconda's Kickstart defaults install the embedded payload through the native `bootc` command and set the selected registry image as the update target.

The embedded payload can be larger than the live RAM-backed overlay. The installer-only `bootc` entrypoint therefore detects Anaconda's `/mnt/sysimage` physical-root argument regardless of where that positional argument appears relative to `--karg` options, creates a private, self-bind-mounted directory on that freshly mounted target filesystem, then temporarily bind-mounts it on `/var/tmp`. This argv-order independence is required because Anaconda bootc integration revisions/backports have emitted both orderings. This is necessary because the containers/image proxy writes exported blobs directly below `/var/tmp`, independently of `TMPDIR`; `TMPDIR` is also pointed at that mount. The self bind satisfies bootc's empty-root verification.

Because that scratch storage belongs to the target filesystem, the wrapper invokes `bootc install` with the upstream-supported `--skip-finalize` option. Deployment, bootloader setup and the final SELinux relabel still complete inside bootc. Only after bootc succeeds does the wrapper unmount `/var/tmp` and the scratch self-bind, delete the installer-only blobs, verify that no scratch mount or process reference remains, and perform the deferred bootc 1.16.7 filesystem sequence: `fstrim --quiet-unsupported -v`, read-only remount, then freeze/thaw for root and a separately mounted `/boot`; VFAT is not frozen. Every other `bootc` command passes through unchanged. This prevents bootc from making its own active scratch filesystem read-only and does not change or relabel the pre-labeled Kobold deployment.

ISO metadata lives at `/usr/lib/image-builder/bootc/iso.yaml` inside the installer image. The project uses the unified `image-builder` CLI; the retired standalone builder is not a supported path.

## SELinux in the live filesystem

Container storage presents an extracted image through an overlay mount labeled for container access. Those mount labels are not valid labels for PID 1 in a live operating system. The installer therefore wraps only the SquashFS creation step: it discards the overlay's `security.selinux` value and writes per-path labels obtained from the installer image's own Fedora `file_contexts` database as SquashFS xattrs. Other xattrs are preserved. The Kobold payload is already pre-labeled and is not relabeled.

This is creation-time labeling of the installer bootstrap filesystem, not a custom policy, runtime `chcon`, or a post-deployment relabel. The ISO boot configuration must keep SELinux enabled and enforcing.

## Local build

The validated payload must already exist in root's container storage. Build only the installer first, inspect it, and then build the ISO:

```bash
sudo PAYLOAD_IMAGE=localhost/kobold:dod \
  TARGET_IMAGE=localhost/kobold:dod \
  INSTALLER_TAG=dod-enforcing \
  ./iso/build-installer.sh

sudo INSTALLER_IMAGE=localhost/kobold-installer:dod-enforcing \
  PAYLOAD_IMAGE=localhost/kobold:dod \
  OUTPUT_DIR="$PWD/output/iso-enforcing" \
  ./iso/build-iso.sh
```

The installer remains interactive so storage/encryption/user choices are not silently imposed by the project. Installer geolocation is explicitly disabled, but Kobold does not force an initial language, keyboard layout or timezone; Anaconda exposes Fedora's normal localization choices to the user.

## Required release acceptance

Upstream generic bootc ISO tooling is still evolving. A successful ISO build is not enough to call the installer validated. Validate BIOS live boot and live SELinux first; only then validate UEFI, perform a graphical interactive install into an empty VM/disk using the intended storage/encryption choices, boot the installed system and execute `tests/iso-acceptance.md`. An automated Kickstart install may supplement this gate, but it does not replace the graphical path shipped to users. Do not use `bootc switch` from a pre-existing Bluefin/Silverblue installation as the acceptance test.
