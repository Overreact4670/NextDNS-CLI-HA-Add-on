#!/usr/bin/with-contenv bashio

# ===========================================================================
# NextDNS CLI Add-on — run.sh
# Reads all options from Home Assistant add-on config and launches the
# nextdns CLI daemon in the foreground.
# ===========================================================================

bashio::log.info "Initialising NextDNS CLI add-on..."

ARGS=()

# ---------------------------------------------------------------------------
# PROFILES (required, repeatable)
# ---------------------------------------------------------------------------
profile_count=0
for profile in $(bashio::config 'profiles'); do
    ARGS+=("-profile" "${profile}")
    profile_count=$((profile_count + 1))
done

if [ "${profile_count}" -eq 0 ]; then
    bashio::log.fatal "No profiles configured! Set at least one profile ID in the add-on options."
    exit 1
fi

bashio::log.info "Profiles configured: ${profile_count}"

# ---------------------------------------------------------------------------
# FORWARDERS (optional, repeatable)
# ---------------------------------------------------------------------------
forwarder_count=0
for fwd in $(bashio::config 'forwarders'); do
    ARGS+=("-forwarder" "${fwd}")
    forwarder_count=$((forwarder_count + 1))
done

if [ "${forwarder_count}" -gt 0 ]; then
    bashio::log.info "Forwarders configured: ${forwarder_count}"
fi

# ---------------------------------------------------------------------------
# LISTEN ADDRESSES (repeatable)
# ---------------------------------------------------------------------------
listen_count=0
for addr in $(bashio::config 'listen'); do
    ARGS+=("-listen" "${addr}")
    listen_count=$((listen_count + 1))
    bashio::log.info "Listening on: ${addr}"
done

if [ "${listen_count}" -eq 0 ]; then
    # Safety fallback — should never happen given the schema default
    bashio::log.warning "No listen addresses configured, falling back to 0.0.0.0:53"
    ARGS+=("-listen" "0.0.0.0:53")
fi

# ---------------------------------------------------------------------------
# CLIENT IDENTIFICATION
# ---------------------------------------------------------------------------
if bashio::config.true 'report_client_info'; then
    ARGS+=("-report-client-info")
    bashio::log.info "Client info reporting: enabled"
fi

DISCOVERY_DNS=$(bashio::config 'discovery_dns')
if ! bashio::var.is_empty "${DISCOVERY_DNS}"; then
    ARGS+=("-discovery-dns" "${DISCOVERY_DNS}")
    bashio::log.info "Discovery DNS: ${DISCOVERY_DNS}"
fi

MDNS=$(bashio::config 'mdns')
ARGS+=("-mdns" "${MDNS}")
bashio::log.info "mDNS: ${MDNS}"

if bashio::config.true 'use_hosts'; then
    ARGS+=("-use-hosts")
fi

# ---------------------------------------------------------------------------
# CACHE
# ---------------------------------------------------------------------------
CACHE_SIZE=$(bashio::config 'cache_size')
ARGS+=("-cache-size" "${CACHE_SIZE}")

CACHE_MAX_AGE=$(bashio::config 'cache_max_age')
ARGS+=("-cache-max-age" "${CACHE_MAX_AGE}")

MAX_TTL=$(bashio::config 'max_ttl')
ARGS+=("-max-ttl" "${MAX_TTL}")

bashio::log.info "Cache: size=${CACHE_SIZE}, max-age=${CACHE_MAX_AGE}, max-ttl=${MAX_TTL}"

# ---------------------------------------------------------------------------
# PRIVACY
# ---------------------------------------------------------------------------
if bashio::config.true 'bogus_priv'; then
    ARGS+=("-bogus-priv")
    bashio::log.info "Bogus private reverse lookups: blocked"
fi

# ---------------------------------------------------------------------------
# CAPTIVE PORTAL DETECTION
# ---------------------------------------------------------------------------
if bashio::config.true 'detect_captive_portals'; then
    ARGS+=("-detect-captive-portals")
    bashio::log.warning "Captive portal detection enabled — DoH may be temporarily bypassed on untrusted networks"
fi

# ---------------------------------------------------------------------------
# PERFORMANCE
# ---------------------------------------------------------------------------
TIMEOUT=$(bashio::config 'timeout')
ARGS+=("-timeout" "${TIMEOUT}")

MAX_INFLIGHT=$(bashio::config 'max_inflight_requests')
ARGS+=("-max-inflight-requests" "${MAX_INFLIGHT}")

bashio::log.info "Performance: timeout=${TIMEOUT}, max-inflight=${MAX_INFLIGHT}"

# ---------------------------------------------------------------------------
# LOGGING / DEBUG
# ---------------------------------------------------------------------------
if bashio::config.true 'log_queries'; then
    ARGS+=("-log-queries")
    bashio::log.warning "Query logging enabled — this is verbose, use for debugging only"
fi

if bashio::config.true 'debug'; then
    ARGS+=("-debug")
    bashio::log.warning "Debug logging enabled"
fi

# ---------------------------------------------------------------------------
# LAUNCH
# ---------------------------------------------------------------------------
bashio::log.info "Starting NextDNS CLI daemon..."
exec nextdns run "${ARGS[@]}"
