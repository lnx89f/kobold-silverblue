# Tuning and power policy

The goal is low heat, good battery life and responsive interactive performance, not synthetic benchmark maximums.

Kobold uses Fedora's TuneD/tuned-ppd stack instead of carrying a large collection of unrelated sysctls. The alpha-era memory tuning, custom ZRAM and audio/Wi-Fi power-disable overrides are intentionally gone.

## Profiles

- **balanced**: upstream TuneD `balanced`; normal default and AC behavior.
- **balanced on battery**: `balanced-battery`; biases EPP toward power efficiency and enables modest panel savings.
- **power-saver**: `kobold-powersave`; includes `balanced-battery`, sets power-oriented EPP, disables CPU boost, requests low-power/quiet platform profile where supported, uses Radeon battery DPM/panel savings and lengthens writeback.
- **performance**: upstream `throughput-performance`; only when explicitly selected in GNOME.

The custom power-saver deliberately has no TuneD `powersave` helper script, because that upstream script may control USB autosuspend. Wi-Fi power saving is configured separately through NetworkManager; USB autosuspend is left to Fedora/kernel/device defaults rather than forced by Kobold.

## Memory

Fedora's ZRAM generator policy is retained. There is no `vm.swappiness=150`, dirty-byte tuning, watermark tuning or custom compression/size override. Those values are performance experiments, not security controls, and must return only if measured on target hardware.

## Measurement

Use `powerstat`, `powertop` (observation only), `sensors`, `tuned-adm active`, `tuned-adm verify` and repeated idle/workload tests. Do not run `powertop --auto-tune` as a permanent policy because it can enable aggressive device autosuspend outside Kobold's spec.

## Bluefin comparison target

Bluefin is the behavioral reference for cool, responsive laptop operation, not a runtime dependency. Kobold deliberately does not import a Bluefin/common layer because the observed thermal behavior is the result of the complete image/hardware policy, not a documented standalone tuning component. The first Kobold baseline therefore uses explicit Fedora TuneD controls that can be inspected and adjusted without changing OS inheritance.
