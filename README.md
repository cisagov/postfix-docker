# postfix-docker 📮🐳 #

[![Build Status](https://travis-ci.com/cisagov/postfix-docker.svg?branch=develop)](https://travis-ci.com/cisagov/postfix-docker)
[![GitHub Build Status](https://github.com/cisagov/postfix-docker/workflows/build/badge.svg)](https://github.com/cisagov/postfix-docker/actions)
[![Total alerts](https://img.shields.io/lgtm/alerts/g/cisagov/postfix-docker.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/cisagov/postfix-docker/alerts/)
[![Language grade: Python](https://img.shields.io/lgtm/grade/python/g/cisagov/postfix-docker.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/cisagov/postfix-docker/context:python)

## Docker Image ##

![MicroBadger Layers](https://img.shields.io/microbadger/layers/cisagov/postfix.svg)
![MicroBadger Size](https://img.shields.io/microbadger/image-size/cisagov/postfix.svg)

Creates a Docker container with an installation of the
[postfix](http://postfix.org) MTA.  Additionally it has an IMAP
server ([dovecot](https://dovecot.org)) for accessing the archvies
of sent email.  All email is BCC'd to the `mailarchive` account.

## Usage ##

### Install ###

Pull `cisagov/postfix` from the Docker repository:

    docker pull cisagov/postfix

Or build `cisagov/postfix` from source:

    git clone https://github.com/cisagov/postfix-docker.git
    cd postfix-docker
    docker-compose build --build-arg VERSION=0.0.1

A sample [docker composition](docker-compose.yml) is included in this repository.
To build and start the container use the command: `docker-compose up`

### Ports ###

This container exposes the following ports:

- 25: `smtp`
- 587: `submission`
- 993: `imaps`

The sample [docker composition](docker-compose.yml) publishes the
exposed ports at 1025, 1587, and 1993.

### Environment Variables ###

Two environment variables are used to generate the configurations at runtime:

- `PRIMARY_DOMAIN`: the domain of the mail server
- `RELAY_IP`: (optional) an IP address that is allowed to relay mail without authentication

### Secrets ###

- `fullchain.pem`: public key
- `privkey.pem`: private key
- `users.txt`: account credentials to create at startup

### Volumes ###

Two optional volumes can be attached to this container to persist the
mail spool directory, as well as the logging directory.  (Note that
the mail logs are available using the docker log command.)

- `/var/spool/postfix`: mail queues
- `/var/log`: system logs

## Contributing ##

We welcome contributions!  Please see [here](CONTRIBUTING.md) for
details.

## License ##

This project is in the worldwide [public domain](LICENSE.md).

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.
