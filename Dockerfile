FROM alpine:latest

RUN apk add --no-cache \
        openldap \
        openldap-back-mdb \
        openldap-clients \
        openldap-overlay-all

RUN rm /etc/openldap/slapd.conf && \
    rmdir /var/lib/openldap/openldap-data

COPY docker-entrypoint.sh /
COPY overlayconfig/ /etc/openldap/overlayconfig

EXPOSE 389

ENTRYPOINT [ "/docker-entrypoint.sh" ]

