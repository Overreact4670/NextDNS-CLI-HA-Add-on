ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_ARCH
ARG BUILD_VERSION

# Labels for HA Supervisor image management
LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

# Install NextDNS CLI from the official Alpine repository.
# The key is fetched over HTTPS — wget validates the TLS certificate chain,
# which provides integrity assurance without needing a hardcoded fingerprint
# that would break on legitimate key rotations.
RUN set -e \
    && wget --timeout=30 --tries=3 --https-only \
        -O /etc/apk/keys/nextdns.pub https://repo.nextdns.io/nextdns.pub \
    && echo "https://repo.nextdns.io/apk" >> /etc/apk/repositories \
    && apk update \
    && apk add --no-cache nextdns \
    && rm -rf /var/cache/apk/* \
    && nextdns version

# Copy and permission startup script
COPY run.sh /run.sh
RUN chmod 755 /run.sh

CMD ["/run.sh"]
