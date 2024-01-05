ARG VERSION=unspecified

FROM debian:11.6-slim

ARG VERSION

###
# For a list of pre-defined annotation keys and value types see:
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
#
# Note: Additional labels are added by the build workflow.
###
LABEL org.opencontainers.image.authors="vm-fusion-dev-group@trio.dhs.gov"
LABEL org.opencontainers.image.vendor="Cybersecurity and Infrastructure Security Agency"

###
# This Docker container does not use an unprivileged user because it
# must be able to modify postfix and opendkim config files and
# therefore must run as root.
###

###
# Upgrade the system
###
RUN apt-get update --quiet --quiet \
    && apt-get upgrade --quiet --quiet

###
# Install everything we need
###
ENV DEPS \
    ca-certificates \
    diceware \
    dovecot-imapd \
    dovecot-lmtpd \
    gettext-base \
    mailutils \
    opendkim \
    opendkim-tools \
    opendmarc \
    postfix \
    procmail \
    sasl2-bin
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get install --quiet --quiet --yes \
    --no-install-recommends --no-install-suggests \
    $DEPS \
    && apt-get --quiet --quiet clean \
    && rm --recursive --force /var/lib/apt/lists/* /tmp/* /var/tmp/*

###
# Create a mailarchive user
###
RUN adduser mailarchive --quiet --disabled-password \
    --shell /usr/sbin/nologin --gecos "Mail Archive"

###
# Setup entrypoint
###
USER root
WORKDIR /root

# Make backups of configurations.  These are modified at startup.
RUN mv /etc/default/opendkim /etc/default/opendkim.orig
RUN mv /etc/default/opendmarc /etc/default/opendmarc.orig
RUN mv /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.orig
RUN mv /etc/postfix/master.cf /etc/postfix/master.cf.orig

COPY src/templates templates/
COPY src/docker-entrypoint.sh src/version.txt ./

###
# Prepare to run
###
VOLUME ["/var/log", "/var/spool/postfix"]
EXPOSE 25/TCP 587/TCP 993/TCP
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["postfix", "-v", "start-fg"]
