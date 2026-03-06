# NextDNS CLI Add-on

This add-on runs the [NextDNS CLI](https://github.com/nextdns/nextdns) as a local DNS-over-HTTPS proxy, enabling per-device identification on your network.

## Why use this instead of just pointing DNS at NextDNS?

When you point your router's DNS to NextDNS directly, all devices show up under your external IP. The CLI proxy runs locally and reports each device's hostname individually, giving you per-device stats and filtering in the NextDNS dashboard.

## Setup

### 1. Get your Profile ID
Log into [nextdns.io](https://nextdns.io), go to your profile, and copy the 6-character Profile ID (e.g. `abc123`).

### 2. Configure the add-on

| Option | Description | Default |
|---|---|---|
| `profile_id` | Your NextDNS profile ID (required) | `""` |
| `report_client_info` | Send device hostnames to NextDNS for per-device stats | `true` |
| `listen` | Address and port the proxy listens on | `localhost:53` |
| `cache_size` | Local DNS cache size | `10MB` |
| `max_ttl` | Max time-to-live for cached entries | `5s` |
| `discovery_dns` | Your router/LAN IP for mDNS hostname discovery (e.g. `192.168.1.1`) | `""` |
| `log_queries` | Log all DNS queries to the add-on log | `false` |

### 3. Point your devices at the add-on

After starting the add-on, configure your router's DHCP to hand out the IP address of your Home Assistant machine as the DNS server. All DNS queries will then flow through the CLI proxy to NextDNS.

> **Note:** The add-on uses `host_network: true` so it shares the host's network namespace. Port 53 on your HA machine will be taken by this add-on.

### 4. (Optional) Use with the NextDNS HA integration

Install the official NextDNS integration (`Settings → Integrations → NextDNS`) alongside this add-on to get stats and control sensors in Home Assistant.

## Troubleshooting

- Check the add-on log for errors.
- Make sure nothing else on your HA machine is using port 53 (e.g. the built-in DNS integration).
- If using a Pi-hole, configure Pi-hole's upstream DNS to point to `127.0.0.1:53` (this add-on) instead of using NextDNS directly.
