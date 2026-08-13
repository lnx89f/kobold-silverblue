# Kobold installer image

The installer environment is built separately from the installed Kobold payload. It uses a digest-pinned Fedora 44 bootc base and contains only the live Anaconda environment and `bootc-generic-iso` requirements. Only the independently validated Kobold payload becomes the installed OS.

`PAYLOAD_IMAGE` is the selected signed Kobold tag copied into the ISO's container storage by Image Builder. `TARGET_IMAGE` is the registry reference (without a transport prefix) that the installed bootc system will track for updates.

The Kickstart fragment uses Anaconda's native `bootc --source-imgref=containers-storage:... --target-imgref=...` path. There is deliberately no `ostreecontainer` and no post-install `bootc switch`.

The unified `image-builder` CLI is the only ISO builder. Its `--bootc-ref` is the installer image and its `--bootc-installer-payload-ref` is the Kobold OCI. ISO metadata is stored at `/usr/lib/image-builder/bootc/iso.yaml`.

Podman's installer-root overlay is container-labeled. `mksquashfs-selinux.py` replaces only those `security.selinux` values at SquashFS creation with per-path labels resolved from the installer image's own Fedora policy. It does not relabel the Kobold payload and does not weaken SELinux.

The installer-only bootc wrapper keeps layer-export scratch data on the target filesystem. It uses bootc's supported `--skip-finalize` contract so that scratch mounts and temporary blobs are removed before root and a separate `/boot` receive bootc 1.16.7's exact trim, read-only remount and non-VFAT freeze/thaw sequence. Deployment, bootloader work and SELinux relabeling remain native bootc operations.

The ISO remains interactive. Anaconda geolocation is disabled, but the boot entry does not force language, keyboard or timezone; Fedora/Anaconda localization choices remain available. Use `build-installer.sh` followed by `build-iso.sh`; run `tests/iso-acceptance.md` on an empty VM/disk before calling a release ISO validated.
