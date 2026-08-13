# Runtime checklist

For changes that touch policy, run the relevant subset after a fresh deployment:

- `pinguim doctor`
- `getenforce`
- `firewall-cmd --get-default-zone`
- `firewall-cmd --zone=drop --list-all`
- `tuned-adm active && tuned-adm verify`
- `resolvectl status`
- `nmcli -f GENERAL,802-11-WIRELESS device show <wifi-device>` as needed
- Bluetooth off-on-off via GNOME
- rootless `podman run --rm quay.io/podman/hello`
- `flatpak remote-list --system` (Firefox is optional/manual)
- `trivy --version && lynis show version`
- `smartctl --version && nvme version && ethtool --version`
- `bootc status`
