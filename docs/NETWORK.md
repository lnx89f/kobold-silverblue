# Network and DNS policy

Kobold aims for minimal unsolicited discovery and information leakage without making ordinary Wi-Fi fragile.

## NetworkManager

Global defaults disable LLMNR/mDNS, DHCP hostname transmission and connectivity probing; enable IPv6 temporary addresses, Wi-Fi scan MAC randomization, stable-per-SSID Wi-Fi MAC randomization and Wi-Fi power saving. A per-connection profile can override these defaults when a corporate, captive-portal or MAC-allowlist network requires it.

## DNS

NetworkManager uses systemd-resolved. Kobold does **not** force all DNS traffic to Cloudflare because doing so can break captive portals, split/private DNS and enterprise networks. Instead:

- per-link DNS learned from the active network remains preferred;
- opportunistic DNS-over-TLS is requested;
- DNSSEC uses allow-downgrade for compatibility;
- Cloudflare IPv4/IPv6 resolvers are configured as explicit fallback servers;
- LLMNR and multicast DNS are disabled.

This fixes the design error from earlier experimental DNS toggles: the fallback is native and resilient, while the active network can still supply DNS necessary to connect.
