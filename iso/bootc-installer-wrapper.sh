#!/usr/bin/env bash
set -euo pipefail

real_bootc=/usr/libexec/kobold-bootc.real

finalize_filesystem() {
  local fsname=$1
  local path=$2
  local magic

  (
    cd "$target"

    # Keep this sequence identical to bootc 1.16.7 finalize_filesystem():
    # trim, remount read-only, then freeze/thaw every non-VFAT filesystem.
    printf 'Trimming %s\n' "$fsname"
    fstrim --quiet-unsupported -v "$path"
    printf 'Finalizing filesystem %s\n' "$fsname"
    mount -o remount,ro "$path"
    magic=$(stat -f -c %t "$path")
    if [[ $magic != 4d44 ]]; then
      fsfreeze -f "$path"
      fsfreeze -u "$path"
    fi
  )
}

assert_scratch_released() {
  local proc_link
  local resolved

  if findmnt --noheadings --mountpoint "$scratch" >/dev/null 2>&1; then
    printf 'bootc scratch remains mounted: %s\n' "$scratch" >&2
    return 1
  fi

  if resolved=$(findmnt --noheadings --output SOURCE --mountpoint /var/tmp 2>/dev/null); then
    if [[ $resolved == "$scratch_source" ]]; then
      printf '/var/tmp still references bootc scratch: %s\n' "$scratch_source" >&2
      return 1
    fi
  fi

  shopt -s nullglob
  for proc_link in /proc/[0-9]*/fd/* /proc/[0-9]*/cwd; do
    if resolved=$(readlink "$proc_link" 2>/dev/null); then
      if [[ $resolved == "$scratch" || $resolved == "$scratch/"* ||
            $resolved == "$scratch (deleted)" || $resolved == "$scratch/"*" (deleted)" ]]; then
        printf 'process reference remains open on bootc scratch: %s -> %s\n' \
          "$proc_link" "$resolved" >&2
        return 1
      fi
    fi
  done
  shopt -u nullglob
}

# Anaconda's native bootc payload task imports one layer at a time through a
# temporary file under /var/tmp (independently of TMPDIR).  The live root is a
# deliberately small RAM-backed overlay; keep that bounded scratch data on the
# already-mounted target filesystem.
# This changes neither the payload nor its pre-existing SELinux labels.
if [[ ${1:-} == install && ${2:-} == to-filesystem ]]; then
  # Anaconda has changed the ordering of the positional ROOT_PATH and --karg
  # options across bootc integration revisions/backports.  Detect the physical
  # root by value instead of assuming it is the final argv element so the same
  # wrapper is used by both graphical installs and automated Kickstart installs.
  args=("$@")
  target_index=-1
  skip_finalize_seen=0
  for i in "${!args[@]}"; do
    if [[ ${args[$i]} == /mnt/sysimage ]]; then
      if ((target_index >= 0)); then
        printf '%s\n' 'multiple Anaconda physical-root arguments found' >&2
        exit 2
      fi
      target_index=$i
    elif [[ ${args[$i]} == --skip-finalize ]]; then
      skip_finalize_seen=1
    fi
  done

  if ((target_index < 0)); then
    exec "$real_bootc" "$@"
  fi

  target=${args[$target_index]}
  target_source=$(findmnt --noheadings --output SOURCE --target "$target")
  [[ -n "$target_source" && "$target_source" != overlay && "$target_source" != LiveOS_rootfs ]]

  scratch=$target/.bootc-installer-tmp
  install -d -m 0700 "$scratch"
  # bootc requires every pre-existing target-root entry to be a mount point.
  # A self bind mount keeps the scratch storage on the target filesystem while
  # making it explicitly ignorable during the empty-root verification.
  mount --bind "$scratch" "$scratch"
  # containers/image's proxy uses /var/tmp directly while exporting blobs from
  # containers-storage.  Cover that live-overlay path for the duration of the
  # deploy so both bootc and its proxy use target-backed scratch space.
  mount --bind "$scratch" /var/tmp

  scratch_source=$(findmnt --noheadings --output SOURCE --mountpoint "$scratch")
  [[ -n $scratch_source ]]

  # --skip-finalize is the upstream-supported contract for callers that must
  # release resources living on the target before it is remounted read-only.
  # bootc still completes deployment, bootloader setup and SELinux relabeling;
  # this wrapper performs only the deferred filesystem finalization below.
  bootc_args=()
  for i in "${!args[@]}"; do
    if ((i == target_index && skip_finalize_seen == 0)); then
      bootc_args+=(--skip-finalize)
    fi
    bootc_args+=("${args[$i]}")
  done

  set +e
  TMPDIR=/var/tmp "$real_bootc" "${bootc_args[@]}"
  status=$?
  set -e

  umount /var/tmp
  umount "$scratch"
  if ((status != 0)); then
    exit "$status"
  fi

  # Remove only installer scratch data. It is not part of the installed OS.
  find "$scratch" -xdev -mindepth 1 -delete
  rmdir "$scratch"
  assert_scratch_released

  boot_is_separate=0
  if findmnt --noheadings --mountpoint "$target/boot" >/dev/null 2>&1; then
    boot_is_separate=1
  fi

  finalize_filesystem root .
  if ((boot_is_separate)); then
    finalize_filesystem boot boot
  fi
  exit 0
fi

exec "$real_bootc" "$@"
