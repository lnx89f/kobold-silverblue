# Recovery

Kobold keeps the Fedora/bootc rollback model. Before a risky user-side change, record `bootc status`. If a newly deployed image fails, select the previous deployment from the bootloader or use the supported bootc rollback workflow.

Persistent `/etc`, `/var` and `/home` are outside the guarantee provided by an OCI image digest. Back up user data and important persistent configuration independently.

The image intentionally does not provide unattended rebooting or a custom rescue mechanism. Recovery should stay as close to Fedora/bootc upstream behavior as possible.
