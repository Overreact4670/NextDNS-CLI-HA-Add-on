# NextDNS CLI Add-on

Runs the [NextDNS CLI](https://github.com/nextdns/nextdns) as a local DNS-over-HTTPS proxy with full per-device identification, multi-profile support, split-horizon DNS, and IPv4/IPv6 dual-stack support.

## Why use this instead of pointing your router's DNS at NextDNS?

When you point your router directly at NextDNS, all devices appear as a single external IP. The CLI proxy runs locally and reports each device's hostname individually — giving you per-device stats, filtering, and logging in the NextDNS dashboard.

---

## Configuration Reference

### Profiles (`profiles`) — required, list

One or more NextDNS profile IDs. The first match wins. Each entry can be a plain profile ID or prefixed with a condition.

| Format | Description |
|---|---|
| `abcdef` | Default profile — matches all clients |
| `10.0.10.0/24=abcdef` | Match an IPv4 subnet |
| `fd00::/64=abcdef` | Match an IPv6 subnet (ULA example) |
| `2001:db8::/32=abcdef` | Match an IPv6 subnet (global unicast example) |
| `00:1c:42:2e:60:4a=abcdef` | Match a specific device by MAC address |
| `eth0=abcdef` | Match all clients behind a network interface |

Conditions are evaluated top-to-bottom. Put specific conditions before the catch-all default.

**Example — multiple VLANs with mixed IPv4/IPv6:**
```yaml
profiles:
  - "10.0.10.0/24=abc123"    # IoT VLAN (IPv4)
  - "fd00:a::0/64=abc123"    # IoT VLAN (IPv6)
  - "10.0.20.0/24=def456"    # Kids VLAN (IPv4)
  - "fd00:b::0/64=def456"    # Kids VLAN (IPv6)
  - "ghijkl"                  # Default for everything else
```

---

### Forwarders (`forwarders`) — optional, list

Route specific domains to alternative DNS servers (split-horizon DNS). Useful for internal domains, Pi-hole, or local resolvers. Both IPv4 and IPv6 upstreams are supported — IPv6 addresses must use bracket notation.

| Format | Description |
|---|---|
| `corp.local=192.168.1.1` | Send `corp.local` to an IPv4 DNS server |
| `corp.local=[fd00::1]` | Send `corp.local` to an IPv6 DNS server |
| `corp.local=[fd00::1],192.168.1.1` | Failover: try IPv6 first, then IPv4 |
| `example.com=https://dns.example.com` | Use DoH for a domain |
| `=192.168.1.1` | Catch-all: send all non-NextDNS queries to this resolver |

**Example:**
```yaml
forwarders:
  - "home.lan=192.168.1.1"
  - "home.lan=[fd00::1]"
  - "corp.internal=10.0.0.53"
```

---

### Listen addresses (`listen`) — list

One or more `address:port` pairs to listen on. To serve both IPv4 and IPv6 clients, include both a standard and an IPv6 address. IPv6 addresses must use bracket notation.

| Example | Description |
|---|---|
| `localhost:53` | IPv4 loopback only |
| `[::1]:53` | IPv6 loopback only |
| `0.0.0.0:53` | All IPv4 interfaces |
| `[::]:53` | All IPv6 interfaces |
| `192.168.1.10:53` | Specific IPv4 interface |
| `[fd00::10]:53` | Specific IPv6 interface |

**Default (dual-stack loopback):**
```yaml
listen:
  - "localhost:53"
  - "[::1]:53"
```

**Full dual-stack on all interfaces:**
```yaml
listen:
  - "0.0.0.0:53"
  - "[::]:53"
```

---

### Client Identification

| Option | Default | Description |
|---|---|---|
| `report_client_info` | `true` | Send device hostnames to NextDNS for per-device stats |
| `discovery_dns` | `""` | IP of your router/DNS for device name discovery. Accepts IPv4 (`192.168.1.1`) or bracketed IPv6 (`[fd00::1]`). Leave empty to auto-detect |
| `mdns` | `"all"` | mDNS hostname discovery. `"all"` = all interfaces, `"eth0"` = specific interface, `"disabled"` = off |
| `use_hosts` | `true` | Use the system `/etc/hosts` file for name resolution |

---

### Cache

| Option | Default | Description |
|---|---|---|
| `cache_size` | `"10MB"` | DNS cache size. Use `0` to disable. Accepts `kB`, `MB`, `GB` |
| `cache_max_age` | `"0s"` | Force cache entries stale after this duration, regardless of TTL. `0s` = disabled |
| `max_ttl` | `"5s"` | Cap the TTL advertised to clients — keeps client caches short so they rely on the CLI cache |

---

### Privacy

| Option | Default | Description |
|---|---|---|
| `bogus_priv` | `true` | Answer reverse lookups for private ranges with NXDOMAIN instead of forwarding upstream. Covers IPv4 private ranges (`10.x`, `172.16.x`, `192.168.x`) **and** IPv6 ULA (`fc00::/7`) and link-local (`fe80::/10`) |

---

### Performance

| Option | Default | Description |
|---|---|---|
| `timeout` | `"5s"` | Maximum duration for an upstream DNS request before failing |
| `max_inflight_requests` | `256` | Maximum number of concurrent DNS queries |

---

### Logging

| Option | Default | Description |
|---|---|---|
| `log_queries` | `false` | Log all DNS queries to the add-on log (verbose — use for debugging) |

---

## Setup Steps

1. **Get your Profile ID(s)** from [nextdns.io](https://nextdns.io) — the 6-character code on your profile page.
2. **Configure the add-on** with at least one entry in `profiles`.
3. **Set `discovery_dns`** to your router's LAN IP for best hostname resolution. Use bracket notation for IPv6: `[fd00::1]`.
4. **Configure `listen`** — the default includes both `localhost:53` and `[::1]:53` for dual-stack loopback. Change to `0.0.0.0:53` / `[::]:53` if you want to serve the whole network directly from HA.
5. **Start the add-on** and check the log for errors.
6. **Point your router's DHCP** DNS setting to your Home Assistant machine's IP (both A and AAAA records if your router supports it).

> **Note:** This add-on uses `host_network: true` and claims port 53 on your HA machine for both IPv4 and IPv6. Make sure nothing else (e.g. `systemd-resolved`) is bound to port 53.

---

## Dual-Stack Network Example

For a typical home network with both IPv4 and IPv6:

```yaml
profiles:
  - "10.0.0.0/8=abcdef"      # All IPv4 LAN clients
  - "fd00::/8=abcdef"         # All IPv6 ULA clients
  - "abcdef"                   # Fallback

listen:
  - "0.0.0.0:53"
  - "[::]:53"

discovery_dns: "192.168.1.1"  # or "[fd00::1]" if your router has IPv6

bogus_priv: true               # Blocks private reverse lookups for both IPv4 and IPv6
```

---

## Optional: Pair with the NextDNS HA Integration

Install the official **NextDNS** integration (`Settings → Integrations → NextDNS`) alongside this add-on to get query stats, block counts, and device status as sensors in Home Assistant.
