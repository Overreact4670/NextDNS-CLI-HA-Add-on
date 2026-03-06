# NextDNS CLI Add-on

Runs the [NextDNS CLI](https://github.com/nextdns/nextdns) as a local DNS-over-HTTPS proxy with full per-device identification, multi-profile support, split-horizon DNS, and more.

## Why use this instead of pointing your router's DNS at NextDNS?

When you point your router directly at NextDNS, all devices appear as a single external IP. The CLI proxy runs locally and reports each device's hostname individually — giving you per-device stats, filtering, and logging in the NextDNS dashboard.

---

## Configuration Reference

### Profiles (`profiles`) — required, list

One or more NextDNS profile IDs. The first match wins. Each entry can be a plain profile ID, or prefixed with a condition:

| Format | Description |
|---|---|
| `abcdef` | Default profile, matches all clients |
| `10.0.3.0/24=abcdef` | Match clients in an IPv4 subnet |
| `2001:db8::/64=abcdef` | Match clients in an IPv6 subnet |
| `00:1c:42:2e:60:4a=abcdef` | Match a specific device by MAC address |
| `eth0=abcdef` | Match all clients behind a network interface |

**Example — different profiles per VLAN:**
```yaml
profiles:
  - "10.0.10.0/24=abc123"   # IoT VLAN
  - "10.0.20.0/24=def456"   # Kids VLAN
  - "ghijkl"                 # Default for everything else
```

---

### Forwarders (`forwarders`) — optional, list

Route specific domains to alternative DNS servers (split-horizon DNS). Useful for internal domains, Pi-hole, or local resolvers.

| Format | Description |
|---|---|
| `corp.local=192.168.1.1` | Send `corp.local` to an internal DNS |
| `example.com=https://dns.example.com` | Use DoH for a domain |
| `=192.168.1.1` | Catch-all forwarder for all non-NextDNS queries |

Multiple servers (failover) can be comma-separated: `corp.local=192.168.1.1,192.168.1.2`

**Example:**
```yaml
forwarders:
  - "home.lan=192.168.1.1"
  - "corp.internal=10.0.0.53"
```

---

### Listen addresses (`listen`) — list

One or more `address:port` pairs to listen on. Repeat to serve multiple interfaces/VLANs.

```yaml
listen:
  - "0.0.0.0:53"       # All interfaces
  - "192.168.10.1:53"  # Or specific interface IPs
```

---

### Client Identification

| Option | Default | Description |
|---|---|---|
| `report_client_info` | `true` | Send device hostnames to NextDNS for per-device stats |
| `discovery_dns` | `""` | IP of your router/DNS server to query for device names. If empty, uses the DHCP-learned address |
| `mdns` | `"all"` | mDNS hostname discovery. `"all"` = all interfaces, `"eth0"` = specific interface, `"disabled"` = off |
| `use_hosts` | `true` | Use the system `/etc/hosts` file for name resolution |

---

### Cache

| Option | Default | Description |
|---|---|---|
| `cache_size` | `"10MB"` | DNS cache size. Use `0` to disable. Accepts `kB`, `MB`, `GB` |
| `cache_max_age` | `"0s"` | Force cache entries stale after this duration, regardless of TTL. `0s` = disabled |
| `max_ttl` | `"5s"` | Cap the TTL advertised to clients. Keeps client-side caches short so they rely on the CLI cache |

---

### Privacy

| Option | Default | Description |
|---|---|---|
| `bogus_priv` | `true` | Answer all reverse lookups for private IP ranges (192.168.x.x, 10.x.x.x, etc.) with NXDOMAIN instead of forwarding upstream |

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

1. **Get your Profile ID(s)** from [nextdns.io](https://nextdns.io) — it's the 6-character code on your profile page.
2. **Configure the add-on** with at least one entry in `profiles`.
3. **Set `discovery_dns`** to your router's LAN IP (e.g. `192.168.1.1`) for best hostname resolution.
4. **Start the add-on** and check the log for any errors.
5. **Point your router's DHCP** DNS setting to the IP of your Home Assistant machine.

> **Note:** This add-on uses `host_network: true` and claims port 53 on your HA machine. Make sure nothing else (e.g. systemd-resolved) is bound to port 53.

---

## Optional: Pair with the NextDNS HA Integration

Install the official **NextDNS** integration (`Settings → Integrations → NextDNS`) alongside this add-on to get query stats, block counts, and device status as sensors in Home Assistant.
