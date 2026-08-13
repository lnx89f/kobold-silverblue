# Architecture

Kobold uses the Fedora-published Silverblue bootable OCI at `quay.io/fedora/fedora-silverblue` as its only OS base and pins the Fedora 44 object by digest. The separate `quay.io/fedora-ostree-desktops/silverblue` SIG stream is not a Kobold dependency. CI verifies the exact Fedora registry/repository/digest and checks that the pinned object contains `fedora-release-silverblue` and `bootc`; it does not pretend that Fedora has published a Cosign policy for this stream when none is documented by the project. Kobold does not use Bluefin, `projectbluefin/common`, Homebrew, RPM Fusion or a custom kernel as runtime inheritance.

The build is intentionally boring:

1. verify/copy the project-owned configuration;
2. remove Fedora Workstation third-party opt-in repository packages and explicitly unwanted workstation applications/services;
3. install the explicit host package set from Fedora repositories;
4. install the official Microsoft VS Code RPM through a temporary, verified repository;
5. configure services/firewall;
6. apply security policy;
7. configure desktop/locale/branding;
8. configure TuneD and network power/privacy policy;
9. configure Flathub without automatic application preinstall;
10. run image invariants and bootc lint.

The final image keeps `ID=fedora` and `VARIANT_ID=silverblue`. Branding changes human-facing presentation only.

`/etc` and `/var` are persistent system state at runtime. Consequently, a `bootc switch` from another image is useful for migration but is not a clean-install equivalence test. The acceptance path for Kobold is an empty-disk ISO installation that installs the Kobold payload directly.
