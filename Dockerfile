ARG BUILD_FROM
FROM $BUILD_FROM

# Install NextDNS CLI from the official Alpine repo
RUN wget -O /etc/apk/keys/nextdns.pub https://repo.nextdns.io/nextdns.pub \
    && echo "https://repo.nextdns.io/apk" >> /etc/apk/repositories \
    && apk update \
    && apk add --no-cache nextdns \
    && rm -rf /var/cache/apk/*

# Copy our startup script
COPY run.sh /
RUN chmod a+x /run.sh

CMD ["/run.sh"]
