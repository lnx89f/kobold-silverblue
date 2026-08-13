# Update and release policy

Kobold follows Fedora Silverblue 44 using the Fedora-published `quay.io/fedora/fedora-silverblue:44` stream. Both build and installer `FROM` references are pinned to a digest. Renovate proposes digest changes in pull requests; it is not allowed to change the Fedora major automatically.

## Channels

- `testing`: rebuilt and published after a successful push to `main`.
- `stable`: promotion of an existing, signed `testing` digest. Promotion does not rebuild.
- immutable tags include date and source SHA for traceability.

Stable promotion is scheduled on the 1st and 15th of each month and can be invoked manually for a critical upstream fix.

## Runtime updates

Kobold masks automatic bootc fetch/apply timers to avoid surprise reboot/apply behavior. The user decides when to move the installed workstation to the published stable image, using bootc normally after reviewing the update.

Major Fedora upgrades are explicit project work: update the spec, base tag/digest, validate package removals and configs, build testing, run clean-install acceptance, then promote.
