# Home Assistant NextDNS CLI App Repository

[![Add repository to HA](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FOverreact4670%2FNextDNS-CLI-HA-Add-on)

A Home Assistant app that runs the [NextDNS CLI](https://github.com/nextdns/nextdns) as a local DNS-over-HTTPS proxy on your Home Assistant machine.

## Why use this?

Pointing your router's DNS directly at NextDNS works, but all traffic appears as a single external IP — you lose per-device stats and filtering. This app runs the CLI locally so every device on your network is identified individually by hostname, giving you full per-device visibility in the NextDNS dashboard.

## Apps in this repository

### NextDNS CLI

Full-featured NextDNS CLI proxy supporting:
- Per-device identification and hostname reporting
- Multiple profiles with conditional matching (subnet, MAC, interface)
- Split-horizon DNS via forwarders
- IPv4 and IPv6 dual-stack
- Local DNS caching
- Captive portal detection
- DNS-over-HTTPS for all LAN devices

## Installation

1. Click the button above, **or** go to **Settings → Apps → App Store → ⋮ → Repositories**
2. Add: `https://github.com/Overreact4670/NextDNS-CLI-HA-Add-on`
3. Find **NextDNS CLI** in the store and install it
4. Set your `profile_id` in the Configuration tab and start the app
5. Point your router's DHCP DNS to your Home Assistant machine's LAN IP

See [nextdns-cli/DOCS.md](/DOCS.md) for full configuration details.
