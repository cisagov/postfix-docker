# Official Docker images are in the form library/<app> while non-official
# images are in the form <user>/<app>.
FROM docker.io/library/debian:trixie-slim


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
# Install everything we need
###
RUN apt-get update --quiet --quiet \
    && DEBIAN_FRONTEND=noninteractive apt-get install --quiet --quiet --yes \
    --no-install-recommends --no-install-suggests \
        ca-certificates=20250419 \
        diceware=1.0.1-1 \
        dovecot-core=1:2.4.1+dfsg1-6+deb13u5 \
        dovecot-sieve=1:2.4.1+dfsg1-6+deb13u5 \
        dovecot-imapd=1:2.4.1+dfsg1-6+deb13u5 \
        dovecot-lmtpd=1:2.4.1+dfsg1-6+deb13u5 \
        gettext-base=0.23.1-2 \
        mailutils=1:3.19-1 \
        opendkim=2.11.0~beta2-9.1+b1 \
        opendkim-tools=2.11.0~beta2-9.1+b1 \
        opendmarc=1.4.2-5 \
        postfix=3.10.5-1~deb13u1 \
        procmail=3.24+really3.22-4 \
        sasl2-bin=2.1.28+dfsg1-9 \
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
EXPOSE 25/tcp 587/tcp 993/tcp
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["postfix", "-v", "start-fg"]
