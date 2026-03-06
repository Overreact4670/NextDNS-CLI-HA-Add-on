#!/usr/bin/with-contenv bashio

# Read configuration from HA options
PROFILE_ID=$(bashio::config 'profile_id')
REPORT_CLIENT_INFO=$(bashio::config 'report_client_info')
CACHE_SIZE=$(bashio::config 'cache_size')
MAX_TTL=$(bashio::config 'max_ttl')
LISTEN=$(bashio::config 'listen')
LOG_QUERIES=$(bashio::config 'log_queries')
DISCOVERY_DNS=$(bashio::config 'discovery_dns')

# Validate that a profile ID was provided
if bashio::var.is_empty "${PROFILE_ID}"; then
    bashio::log.fatal "You must set a NextDNS profile_id in the add-on configuration!"
    exit 1
fi

bashio::log.info "Starting NextDNS CLI..."
bashio::log.info "Profile: ${PROFILE_ID}"
bashio::log.info "Listening on: ${LISTEN}"

# Build the nextdns run command (use 'run' instead of 'install' so it
# runs in the foreground without touching the host's DNS settings)
ARGS="-config ${PROFILE_ID} -listen ${LISTEN} -cache-size ${CACHE_SIZE} -max-ttl ${MAX_TTL}"

if bashio::var.true "${REPORT_CLIENT_INFO}"; then
    ARGS="${ARGS} -report-client-info"
fi

if bashio::var.true "${LOG_QUERIES}"; then
    ARGS="${ARGS} -log-queries"
fi

if ! bashio::var.is_empty "${DISCOVERY_DNS}"; then
    ARGS="${ARGS} -discovery-dns ${DISCOVERY_DNS}"
fi

bashio::log.info "Running: nextdns run ${ARGS}"

# shellcheck disable=SC2086
exec nextdns run ${ARGS}
