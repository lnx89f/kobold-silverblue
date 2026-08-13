#!/usr/bin/python3
"""Create image-builder's live SquashFS with labels from its own policy."""

import os
import re
import stat
import subprocess
import sys
import tempfile

import selinux


REAL_MKSQUASHFS = "/usr/libexec/kobold-mksquashfs.real"
POLICY_RELATIVE = "etc/selinux/targeted/contexts/files/file_contexts"


def pseudo_quote(path: str) -> str:
    if "\n" in path or "\r" in path:
        raise ValueError(f"unsupported newline in filesystem path: {path!r}")
    return '"' + path.replace("\\", "\\\\").replace('"', '\\"') + '"'


def expected_context(handle, path: str, mode: int) -> str | None:
    try:
        result, context = selinux.selabel_lookup_raw(
            handle, path, stat.S_IFMT(mode)
        )
    except OSError:
        return None
    if result < 0 or not context or context == "<<none>>":
        return None
    return context


def label_entry(handle, source: str, relative: str):
    source_path = source if relative == "/" else os.path.join(source, relative)
    target_path = "/" if relative == "/" else "/" + relative
    metadata = os.lstat(source_path)
    mode = metadata.st_mode
    context = expected_context(handle, target_path, mode)
    if context is None:
        return None
    pseudo_path = "/" if relative == "/" else relative
    return metadata, pseudo_path, context


def context_rank(context: str) -> int:
    context_type = context.split(":", 3)[2]
    if context_type in {"default_t", "unlabeled_t"} or context_type.startswith(
        "container_"
    ):
        return 0
    return 1


def generate_pseudo_file(source: str, pseudo_path: str, excludes=()) -> int:
    policy = os.path.join(source, POLICY_RELATIVE)
    if not os.path.isfile(policy):
        raise RuntimeError(f"installer SELinux file-context policy missing: {policy}")
    option = selinux.selinux_opt()
    option.type = selinux.SELABEL_OPT_PATH
    option.value = policy
    handle = selinux.selabel_open(selinux.SELABEL_CTX_FILE, option, 1)
    if not handle:
        raise RuntimeError(f"cannot initialize installer SELinux contexts: {policy}")

    # mksquashfs represents hardlinks as one inode and accepts a pseudo-xattr
    # through only the first pathname it discovers.  Keep that pathname, but
    # prefer a specific OS file context over default_t when another hardlink
    # exposes the same inode at its canonical installed location.
    labels = {}
    symlinks = []

    def record(relative: str) -> None:
        if relative != "/" and any(
            pattern.fullmatch(relative) for pattern in excludes
        ):
            return
        entry = label_entry(handle, source, relative)
        if entry is None:
            return
        metadata, pathname, context = entry
        if stat.S_ISLNK(metadata.st_mode):
            target = os.readlink(os.path.join(source, relative))
            if "\n" in target or "\r" in target:
                raise ValueError(f"unsupported newline in symlink target: {pathname!r}")
            symlinks.append((pathname, context, metadata, target))
            return
        inode = (metadata.st_dev, metadata.st_ino)
        current = labels.get(inode)
        if current is None:
            labels[inode] = [pathname, context]
        elif context_rank(context) > context_rank(current[1]):
            current[1] = context

    try:
        record("/")
        for directory, dirnames, filenames in os.walk(
            source, topdown=True, followlinks=False
        ):
            for name in dirnames + filenames:
                record(os.path.relpath(os.path.join(directory, name), source))

        with open(pseudo_path, "w", encoding="utf-8") as pseudo:
            for pathname, context in labels.values():
                pseudo.write(
                    f"{pseudo_quote(pathname)} x security.selinux={context}\n"
                )
            for pathname, context, metadata, target in symlinks:
                pseudo.write(
                    f"{pseudo_quote(pathname)} S {int(metadata.st_mtime)} "
                    f"0{stat.S_IMODE(metadata.st_mode):o} {metadata.st_uid} "
                    f"{metadata.st_gid} {target}\n"
                )
                pseudo.write(
                    f"{pseudo_quote(pathname)} x security.selinux={context}\n"
                )
    finally:
        selinux.selabel_close(handle)
    return len(labels) + len(symlinks)


def exclusion_patterns(arguments):
    if "-e" not in arguments:
        return ()
    if "-regex" not in arguments:
        raise RuntimeError("SELinux live builder supports only regex excludes")
    exclude_index = arguments.index("-e") + 1
    raw_patterns = arguments[exclude_index:]
    if not raw_patterns or any(pattern.startswith("-") for pattern in raw_patterns):
        raise RuntimeError("unexpected mksquashfs exclude argument layout")
    try:
        return tuple(re.compile(pattern) for pattern in raw_patterns)
    except re.error as error:
        raise RuntimeError(f"invalid mksquashfs exclude regex: {error}") from error


def main() -> int:
    args = sys.argv[1:]
    if len(args) < 2:
        raise RuntimeError("expected mksquashfs SOURCE FILESYSTEM [OPTIONS]")
    if any(
        arg in {"-no-xattrs", "-noX", "-pf", "-p", "-action"}
        for arg in args[2:]
    ):
        raise RuntimeError("conflicting mksquashfs xattr or pseudo-file option")

    source = os.path.realpath(args[0])
    if not os.path.isdir(source):
        raise RuntimeError("SELinux live builder requires exactly one directory source")

    descriptor, pseudo_path = tempfile.mkstemp(
        prefix="kobold-selinux-", suffix=".pseudo", dir="/tmp", text=True
    )
    os.close(descriptor)
    try:
        labels = generate_pseudo_file(
            source, pseudo_path, exclusion_patterns(args[2:])
        )
        if labels == 0:
            raise RuntimeError("installer policy produced no SELinux labels")
        print(f"Kobold: injecting {labels} installer SELinux labels into SquashFS")
        command = [
            REAL_MKSQUASHFS,
            args[0],
            args[1],
            "-exit-on-error",
            "-xattrs-exclude",
            "^security[.]selinux$",
            "-pf",
            pseudo_path,
            "-action",
            "exclude @ type(l)",
            *args[2:],
        ]
        return subprocess.run(command, check=False).returncode
    finally:
        os.unlink(pseudo_path)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError) as error:
        print(f"kobold-mksquashfs-selinux: {error}", file=sys.stderr)
        raise SystemExit(1) from error
