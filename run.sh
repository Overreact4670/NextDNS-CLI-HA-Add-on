#!/usr/bin/with-contenv bashio

# ===========================================================================
# NextDNS CLI App — run.sh
# Reads all options from Home Assistant App config and launches the
# nextdns CLI daemon in the foreground.
# ===========================================================================

bashio::log.info "Initialising NextDNS CLI App..."

ARGS=()

# ---------------------------------------------------------------------------
# PROFILES (required, repeatable)
# Uses bashio array notation to safely handle values with special characters.
# ---------------------------------------------------------------------------
profile_count=0
while read -r profile; do
    [ -z "${profile}" ] && continue
    ARGS+=("-profile" "${profile}")
    profile_count=$((profile_count + 1))
done <<< "$(bashio::config 'profiles[]')"

if [ "${profile_count}" -eq 0 ]; then
    bashio::log.fatal "No profiles configured! Set at least one profile ID in the App options."
    exit 1
fi

bashio::log.info "Profiles configured: ${profile_count}"

# ---------------------------------------------------------------------------
# FORWARDERS (optional, repeatable)
# ---------------------------------------------------------------------------
forwarder_count=0
if bashio::config.exists 'forwarders' && [ "$(bashio::config 'forwarders[]' 2>/dev/null | wc -l)" -gt 0 ]; then
    while read -r fwd; do
        [ -z "${fwd}" ] && continue
        ARGS+=("-forwarder" "${fwd}")
        forwarder_count=$((forwarder_count + 1))
    done <<< "$(bashio::config 'forwarders[]')"
fi

if [ "${forwarder_count}" -gt 0 ]; then
    bashio::log.info "Forwarders configured: ${forwarder_count}"
fi

# ---------------------------------------------------------------------------
# LISTEN ADDRESSES (repeatable)
# ---------------------------------------------------------------------------
listen_count=0
while read -r addr; do
    [ -z "${addr}" ] && continue
    ARGS+=("-listen" "${addr}")
    listen_count=$((listen_count + 1))
    bashio::log.info "Listening on: ${addr}"
done <<< "$(bashio::config 'listen[]')"

if [ "${listen_count}" -eq 0 ]; then
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

if bashio::config.exists 'discovery_dns' && bashio::config.has_value 'discovery_dns'; then
    DISCOVERY_DNS=$(bashio::config 'discovery_dns')
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
    bashio::log.warning "Query logging enabled — verbose, use for debugging only"
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
