# postfix-docker 📮🐳 #

[![GitHub Build Status](https://github.com/cisagov/postfix-docker/workflows/build/badge.svg)](https://github.com/cisagov/postfix-docker/actions/workflows/build.yml)
[![CodeQL](https://github.com/cisagov/postfix-docker/workflows/CodeQL/badge.svg)](https://github.com/cisagov/postfix-docker/actions/workflows/codeql-analysis.yml)
[![Known Vulnerabilities](https://snyk.io/test/github/cisagov/postfix-docker/badge.svg)](https://snyk.io/test/github/cisagov/postfix-docker)

## Docker Image ##

[![Docker Pulls](https://img.shields.io/docker/pulls/cisagov/postfix)](https://hub.docker.com/r/cisagov/postfix)
[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/cisagov/postfix)](https://hub.docker.com/r/cisagov/postfix)
[![Platforms](https://img.shields.io/badge/platforms-amd64%20%7C%20arm%2Fv6%20%7C%20arm%2Fv7%20%7C%20arm64%20%7C%20ppc64le%20%7C%20s390x-blue)](https://hub.docker.com/r/cisagov/postfix/tags)

Creates a Docker container with an installation of the
[postfix](http://postfix.org) MTA.  Additionally it has an IMAP
server ([dovecot](https://dovecot.org)) for accessing the archvies
of sent email.  All email is BCC'd to the `mailarchive` account.

## Running ##

### Running with Docker ###

To run the `cisagov/postfix` image via Docker:

```console
docker run cisagov/postfix:0.0.4
```

### Running with Docker Compose ###

1. Create a `docker-compose.yml` file similar to the one below to use [Docker Compose](https://docs.docker.com/compose/)
or use the [sample `docker-compose.yml`](docker-compose.yml) provided with
this repository.

    ```yaml
    ---
    version: "3.7"

    services:
      postfix:
        build:
          # VERSION must be specified on the command line:
          # e.g., --build-arg VERSION=0.0.4
          context: .
          dockerfile: Dockerfile
        image: cisagov/postfix
        init: true
        restart: always
        environment:
          - PRIMARY_DOMAIN=example.com
          - RELAY_IP=172.16.202.1/32
        networks:
          front:
            ipv4_address: 172.16.202.2
        ports:
          - target: "25"
            published: "1025"
            protocol: tcp
            mode: host
          - target: "587"
            published: "1587"
            protocol: tcp
            mode: host
          - target: "993"
            published: "1993"
            protocol: tcp
            mode: host

    networks:
      front:
        driver: bridge
        ipam:
          driver: default
          config:
            - subnet: 172.16.202.0/24
    ```

1. Start the container and detach:

    ```console
    docker-compose up --detach
    ```

## Using secrets with your container ##

This container also supports passing sensitive values via [Docker
secrets](https://docs.docker.com/engine/swarm/secrets/).  Passing sensitive
values like your credentials can be more secure using secrets than using
environment variables.  See the
[secrets](#secrets) section below for a table of all supported secret files.

1. To use secrets, populate the following files in the `src/secrets` directory:

- `fullchain.pem`
- `privkey.pem`
- `users.txt`

1. Then add the secrets to your `docker-compose.yml` file:

    ```yaml
    ---
    version: "3.7"

    secrets:
      fullchain_pem:
        file: ./src/secrets/fullchain.pem
      privkey_pem:
        file: ./src/secrets/privkey.pem
      users_txt:
        file: ./src/secrets/users.txt

    services:
      postfix:
        build:
          # VERSION must be specified on the command line:
          # e.g., --build-arg VERSION=0.0.4
          context: .
          dockerfile: Dockerfile
        image: cisagov/postfix
        init: true
        restart: always
        environment:
          - PRIMARY_DOMAIN=example.com
          - RELAY_IP=172.16.202.1/32
        networks:
          front:
            ipv4_address: 172.16.202.2
        ports:
          - target: "25"
            published: "1025"
            protocol: tcp
            mode: host
          - target: "587"
            published: "1587"
            protocol: tcp
            mode: host
          - target: "993"
            published: "1993"
            protocol: tcp
            mode: host
        secrets:
          - source: fullchain_pem
            target: fullchain.pem
          - source: privkey_pem
            target: privkey.pem
          - source: users_txt
            target: users.txt

    networks:
      front:
        driver: bridge
        ipam:
          driver: default
          config:
            - subnet: 172.16.202.0/24
    ```

## Updating your container ##

### Docker Compose ###

1. Pull the new image from Docker hub:

    ```console
    docker-compose pull
    ```

1. Recreate the running container by following the [previous instructions](#running-with-docker-compose):

    ```console
    docker-compose up --detach
    ```

### Docker ###

1. Stop the running container:

    ```console
    docker stop <container_id>
    ```

1. Pull the new image:

    ```console
    docker pull cisagov/postfix:0.0.4
    ```

1. Recreate and run the container by following the [previous instructions](#running-with-docker).

## Image tags ##

The images of this container are tagged with [semantic
versions](https://semver.org) of the underlying Postfix project that they
containerize.  It is recommended that most users use a version tag (e.g.
`:0.0.4`).

| Image:tag | Description |
|-----------|-------------|
|`cisagov/postfix:0.0.4`| An exact release version. |
|`cisagov/postfix:0.0`| The most recent release matching the major and minor version numbers. |
|`cisagov/postfix:0`| The most recent release matching the major version number. |
|`cisagov/postfix:edge` | The most recent image built from a merge into the `develop` branch of this repository. |
|`cisagov/postfix:nightly` | A nightly build of the `develop` branch of this repository. |
|`cisagov/postfix:latest`| The most recent release image pushed to a container registry.  Pulling an image using the `:latest` tag [should be avoided.](https://vsupalov.com/docker-latest-tag/) |

See the [tags tab](https://hub.docker.com/r/cisagov/postfix/tags) on Docker
Hub for a list of all the supported tags.

## Volumes ##

| Mount point | Purpose |
|-------------|---------|
| `/var/log` | System logs |
| `/var/spool/postfix` | Mail queues |

## Ports ##

The following ports are exposed by this container:

| Port | Purpose        |
|------|----------------|
| 25 | SMTP relay |
| 587 | Mail submission |
| 993 | IMAPS |

The sample [Docker composition](docker-compose.yml) publishes the
exposed ports at 1025, 1587, and 1993, respectively.

## Environment variables ##

### Required ###

| Name  | Purpose |
|-------|---------|
| `PRIMARY_DOMAIN` | The primary domain of the mail server. |

### Optional ###

| Name  | Purpose | Default |
|-------|---------|---------|
| `RELAY_IP` | An IP address that is allowed to relay mail without authentication. | `null` |

## Secrets ##

| Filename     | Purpose |
|--------------|---------|
| `fullchain.pem` | Public key for the Postfix server. |
| `privkey.pem` | Private key for the Postfix server. |
| `users.txt` | Mail account credentials to create at startup. |

## Building from source ##

Build the image locally using this git repository as the [build context](https://docs.docker.com/engine/reference/commandline/build/#git-repositories):

```console
docker build \
  --build-arg VERSION=0.0.4 \
  --tag cisagov/postfix:0.0.4 \
  https://github.com/cisagov/postfix-docker.git#develop
```

## Cross-platform builds ##

To create images that are compatible with other platforms, you can use the
[`buildx`](https://docs.docker.com/buildx/working-with-buildx/) feature of
Docker:

1. Copy the project to your machine using the `Code` button above
   or the command line:

    ```console
    git clone https://github.com/cisagov/postfix-docker.git
    cd postfix-docker
    ```

1. Create the `Dockerfile-x` file with `buildx` platform support:

    ```console
    ./buildx-dockerfile.sh
    ```

1. Build the image using `buildx`:

    ```console
    docker buildx build \
      --file Dockerfile-x \
      --platform linux/amd64 \
      --build-arg VERSION=0.0.4 \
      --output type=docker \
      --tag cisagov/postfix:0.0.4 .
    ```

## Contributing ##

We welcome contributions!  Please see [`CONTRIBUTING.md`](CONTRIBUTING.md) for
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
