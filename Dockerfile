# Official Docker images are in the form library/<app> while non-official
# images are in the form <user>/<app>.
FROM docker.io/library/debian:bullseye-slim


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
        ca-certificates=20210119 \
        diceware=0.9.6-1 \
        dovecot-imapd=1:2.3.13+dfsg1-2+deb11u4 \
        dovecot-lmtpd=1:2.3.13+dfsg1-2+deb11u4 \
        gettext-base=0.21-4 \
        mailutils=1:3.10-3+b1 \
        opendkim=2.11.0~beta2-4+deb11u1 \
        opendkim-tools=2.11.0~beta2-4+deb11u1 \
        opendmarc=1.4.0~beta1+dfsg-6+deb11u1 \
        postfix=3.5.25-0+deb11u1 \
        procmail=3.22-26+deb11u1 \
        sasl2-bin=2.1.27+dfsg-2.1+deb11u1 \
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
