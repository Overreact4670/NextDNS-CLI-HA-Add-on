#!/usr/bin/with-contenv bashio

# ---------------------------------------------------------------------------
# NextDNS CLI Add-on - run.sh
# Reads all options from HA config and builds the nextdns run command.
# ---------------------------------------------------------------------------

# --- Profiles (required, repeatable) ---
PROFILES=()
for profile in $(bashio::config 'profiles'); do
    PROFILES+=("-profile" "${profile}")
done

if [ ${#PROFILES[@]} -eq 0 ]; then
    bashio::log.fatal "You must configure at least one profile in the add-on options!"
    exit 1
fi

# --- Forwarders (optional, repeatable) ---
FORWARDERS=()
for fwd in $(bashio::config 'forwarders'); do
    FORWARDERS+=("-forwarder" "${fwd}")
done

# --- Listen addresses (repeatable) ---
LISTEN=()
for addr in $(bashio::config 'listen'); do
    LISTEN+=("-listen" "${addr}")
done

if [ ${#LISTEN[@]} -eq 0 ]; then
    LISTEN=("-listen" "localhost:53")
fi

# --- Client identification ---
REPORT_CLIENT_INFO=$(bashio::config 'report_client_info')
DISCOVERY_DNS=$(bashio::config 'discovery_dns')
MDNS=$(bashio::config 'mdns')
USE_HOSTS=$(bashio::config 'use_hosts')

# --- Cache ---
CACHE_SIZE=$(bashio::config 'cache_size')
CACHE_MAX_AGE=$(bashio::config 'cache_max_age')
MAX_TTL=$(bashio::config 'max_ttl')

# --- Privacy ---
BOGUS_PRIV=$(bashio::config 'bogus_priv')

# --- Performance ---
TIMEOUT=$(bashio::config 'timeout')
MAX_INFLIGHT=$(bashio::config 'max_inflight_requests')

# --- Logging ---
LOG_QUERIES=$(bashio::config 'log_queries')

# ---------------------------------------------------------------------------
# Build argument array
# ---------------------------------------------------------------------------
ARGS=()

# Profiles
ARGS+=("${PROFILES[@]}")

# Forwarders
if [ ${#FORWARDERS[@]} -gt 0 ]; then
    ARGS+=("${FORWARDERS[@]}")
fi

# Listen
ARGS+=("${LISTEN[@]}")

# Client info
if bashio::var.true "${REPORT_CLIENT_INFO}"; then
    ARGS+=("-report-client-info")
fi

if ! bashio::var.is_empty "${DISCOVERY_DNS}"; then
    ARGS+=("-discovery-dns" "${DISCOVERY_DNS}")
fi

ARGS+=("-mdns" "${MDNS}")

if bashio::var.true "${USE_HOSTS}"; then
    ARGS+=("-use-hosts")
fi

# Cache
ARGS+=("-cache-size" "${CACHE_SIZE}")
ARGS+=("-cache-max-age" "${CACHE_MAX_AGE}")
ARGS+=("-max-ttl" "${MAX_TTL}")

# Privacy
if bashio::var.true "${BOGUS_PRIV}"; then
    ARGS+=("-bogus-priv")
fi

# Performance
ARGS+=("-timeout" "${TIMEOUT}")
ARGS+=("-max-inflight-requests" "${MAX_INFLIGHT}")

# Logging
if bashio::var.true "${LOG_QUERIES}"; then
    ARGS+=("-log-queries")
fi

# ---------------------------------------------------------------------------
# Launch
# ---------------------------------------------------------------------------
bashio::log.info "Starting NextDNS CLI..."
bashio::log.info "Profiles:   ${PROFILES[*]}"
bashio::log.info "Listen:     ${LISTEN[*]}"
bashio::log.info "mDNS:       ${MDNS}"
bashio::log.info "Cache size: ${CACHE_SIZE}"

exec nextdns run "${ARGS[@]}"
