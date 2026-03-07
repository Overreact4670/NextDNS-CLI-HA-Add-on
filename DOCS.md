# NextDNS CLI App

Runs the [NextDNS CLI](https://github.com/nextdns/nextdns) as a local DNS-over-HTTPS (DoH) proxy on your Home Assistant machine, providing full per-device identification, multi-profile support, split-horizon DNS, and IPv4/IPv6 dual-stack out of the box.

---

## Why use this instead of pointing your router's DNS at NextDNS directly?

When you point your router at `45.90.28.0` (NextDNS's IP), all devices appear as a single external IP in the NextDNS dashboard — you lose per-device stats and filtering. This App runs the CLI proxy locally so every device is identified individually by hostname.

```
Your devices  →  HA machine port 53  →  NextDNS CLI  →  NextDNS cloud (DoH/HTTPS)
```

---

## Quick Start

1. Install the App and open the **Configuration** tab
2. Set your **Profile ID** (the 6-character code from [nextdns.io](https://nextdns.io))
3. Optionally set `discovery_dns` to your router's LAN IP for best hostname detection
4. Start the App
5. In your router's DHCP settings, set the DNS server to your **Home Assistant machine's LAN IP**

> **Important:** Do not enter NextDNS's IP addresses (`45.90.28.0` etc.) anywhere on your router — the CLI handles the upstream DoH connection itself.

---

## Configuration Reference

---

### `profiles` — required, list

Your NextDNS profile ID(s). Entries are evaluated top-to-bottom and the **first match wins**, so put specific conditions before the catch-all default.

| Format | Matches |
|---|---|
| `abcdef` | All clients (use as the last/default entry) |
| `192.168.10.0/24=abcdef` | An IPv4 subnet |
| `fd00:a::/64=abcdef` | An IPv6 ULA subnet |
| `2001:db8::/32=abcdef` | An IPv6 global unicast subnet |
| `00:1c:42:2e:60:4a=abcdef` | A specific device by MAC address |
| `eth0=abcdef` | All clients behind a specific network interface |

**Single profile (most common):**
```yaml
profiles:
  - "abcdef"
```

**Multiple profiles — different rules per VLAN (IPv4 + IPv6 pairs):**
```yaml
profiles:
  - "192.168.10.0/24=abc123"   # IoT VLAN IPv4
  - "fd00:a::/64=abc123"        # IoT VLAN IPv6
  - "192.168.20.0/24=def456"   # Kids VLAN IPv4
  - "fd00:b::/64=def456"        # Kids VLAN IPv6
  - "ghijkl"                    # Default for everything else
```

**Per-device profile (e.g. a single strict device):**
```yaml
profiles:
  - "00:1c:42:2e:60:4a=strict99"
  - "abcdef"
```

---

### `forwarders` — optional, list

Route queries for specific domains to alternative DNS servers (split-horizon DNS). Useful for internal domains, Pi-hole, or local resolvers. NextDNS is still used for everything else.

| Format | Description |
|---|---|
| `corp.local=192.168.1.1` | Send `corp.local` to an IPv4 DNS server |
| `corp.local=[fd00::1]` | Send `corp.local` to an IPv6 DNS server (bracket notation required) |
| `corp.local=[fd00::1],192.168.1.1` | Failover: try IPv6 first, then IPv4 |
| `corp.local=https://dns.example.com#1.2.3.4` | Use DoH with a bootstrap IP |
| `=192.168.1.1` | Catch-all: send all non-matched queries to this resolver |

**Example — internal domain + Pi-hole:**
```yaml
forwarders:
  - "home.lan=192.168.1.1"
  - "home.lan=[fd00::1]"
  - "ads.local=192.168.1.200"
```

---

### `listen` — list

Addresses and ports the proxy listens on. The default binds to all IPv4 and IPv6 interfaces, which is required to accept queries from other devices on your network.

| Value | Description |
|---|---|
| `0.0.0.0:53` | All IPv4 interfaces — **required for LAN devices to reach the proxy** |
| `[::]:53` | All IPv6 interfaces |
| `192.168.1.100:53` | Specific IPv4 interface only |
| `[fd00::100]:53` | Specific IPv6 interface only |
| `localhost:53` | IPv4 loopback only — HA machine itself only, not LAN devices |
| `[::1]:53` | IPv6 loopback only — HA machine itself only, not LAN devices |

**Default (recommended — serves all LAN devices over IPv4 and IPv6):**
```yaml
listen:
  - "0.0.0.0:53"
  - "[::]:53"
```

> **Note:** This App uses `host_network: true`, so it shares the HA machine's network stack. Port 53 on your HA machine will be claimed by this App — make sure nothing else is using it (e.g. `systemd-resolved`).

---

### `report_client_info` — bool (default: `true`)

Embeds device information with each DNS query sent to NextDNS, enabling per-device stats, filtering, and logging in the NextDNS dashboard. Disable only if you want all devices to appear anonymous.

---

### `discovery_dns` — string (default: `""`)

The IP address of a DNS server used to look up LAN client hostnames. If left empty, the address learned automatically via DHCP is used (usually your router).

Set this explicitly to your router's LAN IP for the most reliable hostname discovery:

```yaml
discovery_dns: "192.168.1.1"      # IPv4
# or
discovery_dns: "[fd00::1]"         # IPv6 (bracket notation)
```

Only active when `report_client_info` is `true`.

---

### `mdns` — string (default: `"all"`)

Controls mDNS (multicast DNS) hostname discovery, which lets the CLI identify devices by their `.local` hostnames.

| Value | Description |
|---|---|
| `"all"` | Listen on all network interfaces (recommended) |
| `"eth0"` | Limit mDNS to a specific interface |
| `"disabled"` | Disable mDNS entirely |

---

### `use_hosts` — bool (default: `true`)

When enabled, the CLI consults the system `/etc/hosts` file before sending queries upstream. Useful if you have static hostname mappings.

---

### `cache_size` — string (default: `"10MB"`)

Size of the local DNS cache. Accepts `kB`, `MB`, or `GB`. Set to `"0"` to disable caching entirely.

The cache is automatically flushed when your NextDNS profile is updated, so cached responses are always consistent with your current settings.

---

### `cache_max_age` — string (default: `"0s"`)

Forces cache entries to be considered stale after this duration, regardless of their actual TTL. `"0s"` means disabled — entries live according to their real TTL.

Useful when you want profile changes to propagate faster than the DNS TTL would normally allow.

---

### `max_ttl` — string (default: `"5s"`)

Caps the TTL value advertised to clients. If a DNS record has a higher TTL, clients will be told `max_ttl` instead, encouraging them to re-query the CLI cache more frequently rather than caching locally.

Best used together with `cache_size` > 0.

---

### `bogus_priv` — bool (default: `true`)

When enabled, all reverse DNS lookups (`PTR` queries) for private and reserved address ranges are answered with `NXDOMAIN` instead of being forwarded upstream. This prevents leaking internal network topology to external resolvers.

Covered ranges:

| Type | Ranges |
|---|---|
| IPv4 private | `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` |
| IPv4 link-local | `169.254.0.0/16` |
| IPv4 loopback | `127.0.0.0/8` |
| IPv6 ULA | `fc00::/7` |
| IPv6 link-local | `fe80::/10` |
| IPv6 loopback | `::1` |

---

### `detect_captive_portals` — bool (default: `false`)

When enabled, the CLI detects captive portals (e.g. hotel, airport, or coffee shop Wi-Fi login pages) and temporarily falls back to unencrypted system DNS so the portal page can be reached.

> **Security warning:** When a captive portal is detected, DoH is temporarily disabled and DNS queries are sent unencrypted. Only enable this if your HA machine connects to networks where captive portals are expected. Leave disabled on a home network.

---

### `timeout` — string (default: `"5s"`)

Maximum time the CLI will wait for a response from the upstream NextDNS DoH server before the query fails. Increase slightly if you're on a high-latency connection.

---

### `max_inflight_requests` — int (default: `256`)

Maximum number of DNS queries the CLI will handle simultaneously. Increasing this can help on busy networks with many simultaneous devices, but each additional slot uses memory.

---

### `log_queries` — bool (default: `false`)

Logs every DNS query to the App log. Very verbose — only useful for debugging which domains specific devices are resolving.

---

### `debug` — bool (default: `false`)

Enables debug-level logging for the CLI daemon itself. Outputs internal state and connection information. Only useful when diagnosing App or upstream connectivity issues.

---

## Network Setup Guide

### Step 1 — Reserve a static IP for your HA machine

In your router's DHCP settings, assign a permanent IP to your Home Assistant machine by its MAC address. This ensures the DNS address you hand out to devices never changes.

### Step 2 — Set DHCP DNS to your HA machine's IP

In your router's **LAN → DHCP Server** settings, set **DNS Server 1** to your HA machine's LAN IP (e.g. `192.168.1.100`). This tells all devices on your network to use the CLI proxy automatically.

### Step 3 — (Optional) Set the router's own DNS

In **WAN → Internet Connection**, set **DNS Server 1** to your HA machine's LAN IP so the router itself also routes through NextDNS.

### Step 4 — Verify

Check the **NextDNS dashboard → Logs** — you should see queries appearing within seconds of making any DNS request from a LAN device, each labelled with the device's hostname.

---

## IPv6 Notes

The default `listen` config includes `[::]:53` for IPv6. However, a stable IPv6 address on your HA machine is needed before you can use it as a DNS server for other devices.

- **`fe80::` (link-local)** — not usable as a DNS server address
- **`2601::` / `2001::` (ISP-assigned global)** — changes periodically, not reliable
- **`fd00::` (ULA)** — stable private IPv6, ideal for DNS — requires manual assignment or router ULA prefix advertisement

For most home setups, using only the IPv4 address as your DNS server is simpler and works perfectly — devices still get AAAA records back, they just ask via IPv4.

---

## Using with the NextDNS Home Assistant Integration

Install the official **NextDNS** integration (`Settings → Integrations → Add Integration → NextDNS`) alongside this App. It connects to the NextDNS API using your API key and exposes entities like:

- Total queries count
- Blocked queries count
- Block ratio
- Device connection status
- Button to clear DNS logs

This pairs well with the CLI App — the CLI handles local proxying and device identification, while the integration gives you HA sensors and automations based on your NextDNS stats.

---

## Troubleshooting

**Queries not appearing in NextDNS dashboard**
- Confirm the App is running (check the log tab)
- Make sure `listen` includes `0.0.0.0:53` — `localhost:53` only accepts connections from the HA machine itself
- Confirm your router's DHCP DNS is set to the HA machine's LAN IP, not NextDNS's IP directly
- Check nothing else is bound to port 53 on the HA machine

**Devices showing as unknown or by IP only**
- Set `discovery_dns` to your router's LAN IP
- Ensure `report_client_info` is `true`
- Ensure `mdns` is `"all"` (or the correct interface name)

**App fails to start**
- Check that `profiles` contains at least one entry
- Check the log for specific error messages
- Enable `debug: true` temporarily for more detail
