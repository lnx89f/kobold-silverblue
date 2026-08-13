# Source reuse decisions

Pinguim, Akatsuki and Kobold alpha were treated as implementation references rather than authoritative configurations.

Kept/reworked from earlier projects: direct Fedora-published Silverblue inheritance, Microsoft VS Code verification, default-off Bluetooth, strict firewalld policy, rootful Podman socket masking, modular libvirt, image invariants, Fedora-native localization behavior, branding assets and the small `pinguim doctor` diagnostic interface.

Rejected/replaced: Bluefin as runtime base, alpha's custom ZRAM/memory sysctls, disabled Wi-Fi/audio power saving, SSH server, brittle Niri default-config patching, GNOME Software, broad service/application inheritance, cross-base ISO switch flows and silent deletion of unexpected repositories.

Bluefin/Finpilot remain valuable references for composition discipline, power behavior, Flatpak preinstall, update automation and installer engineering. Kobold does not import their complete runtime policy.

## Bluefin/common decision

`projectbluefin/common` is intentionally not imported. It is a broad shared configuration layer (desktop defaults, setup hooks, container policies, shell/Just/Homebrew-related integration and other Bluefin opinions), not a self-contained thermal/power module. Pulling it only to chase Bluefin's battery/temperature behavior would widen Kobold's inherited policy without proving which component caused that behavior.

Kobold instead expresses the desired power behavior directly with Fedora's TuneD/tuned-ppd stack and NetworkManager Wi-Fi power saving. This makes the tuning visible, reviewable and replaceable independently of Bluefin. Matching Bluefin's exact thermal result is an empirical acceptance target on the notebook, not an assumed property of importing a layer.
