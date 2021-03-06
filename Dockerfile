ARG VERSION=unspecified

FROM debian:buster-slim

ARG VERSION

# For a list of pre-defined annotation keys and value types see:
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
# Note: Additional labels are added by the build workflow.
LABEL org.opencontainers.image.authors="mark.feldhousen@cisa.dhs.gov"
LABEL org.opencontainers.image.vendor="Cyber and Infrastructure Security Agency"

RUN apt-get update && \
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
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
sasl2-bin \
&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser mailarchive --quiet --disabled-password \
--shell /usr/sbin/nologin --gecos "Mail Archive"

USER root
WORKDIR /root

# make backups of configurations.  These are modified at startup.
RUN mv /etc/postfix/master.cf /etc/postfix/master.cf.orig
RUN mv /etc/default/opendkim /etc/default/opendkim.orig
RUN mv /etc/default/opendmarc /etc/default/opendmarc.orig

COPY ./src/templates ./templates/
COPY ./src/docker-entrypoint.sh ./src/version.txt ./

VOLUME ["/var/log", "/var/spool/postfix"]
EXPOSE 25/TCP 587/TCP 993/TCP

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["postfix", "-v", "start-fg"]
