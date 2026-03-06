# Home Assistant NextDNS CLI Add-on Repository

[![Add repository to HA](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FOverreact4670%2FNextDNS-CLI-HA-Add-on)

This repository contains a Home Assistant add-on for running the [NextDNS CLI](https://github.com/nextdns/nextdns) as a local DNS-over-HTTPS proxy.

## Add-ons

### NextDNS CLI

Runs the NextDNS CLI proxy on your Home Assistant machine, enabling:
- Per-device identification and stats in the NextDNS dashboard
- Local DNS caching
- DNS-over-HTTPS for all LAN devices

## Installation

1. Click the button above, or go to **Settings → Add-ons → Add-on store → ⋮ → Repositories**
2. Add: `https://github.com/Overreact4670/ha-addon-nextdns`
3. Find **NextDNS CLI** in the store and install it
4. Configure your Profile ID and start the add-on

See [DOCS.md](nextdns-cli/DOCS.md) for full configuration details.
