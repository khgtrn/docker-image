# docker-image

Custom PHP and Node.js images, built from the official images and pushed to Docker Hub.

| Repository | Tags | Based on |
|---|---|---|
| `khgtrn/php` | `8.5-fpm-alpine`, `8.4-fpm-alpine`, `8.3-fpm-alpine`, `8.2-fpm-alpine` | `php:<version>-fpm-alpine` |
| `khgtrn/node` | `26-trixie-slim`, `24-trixie-slim`, `22-trixie-slim`, `20-trixie-slim` | `node:<version>-trixie-slim` |

## What is in the images

### PHP (`khgtrn/php`)

On top of the extensions in the official image:

| Group | Extensions / tools |
|---|---|
| SQL Server | `sqlsrv`, `pdo_sqlsrv`, Microsoft ODBC Driver 18 (`msodbcsql18`), `pdo_dblib` |
| ODBC | `odbc`, `pdo_odbc` |
| MySQL | `mysqli`, `pdo_mysql` |
| PostgreSQL | `pgsql`, `pdo_pgsql` |
| Other | `redis`, `gd` (incl. AVIF/WebP/JPEG/FreeType), `zip`, `bcmath`, `sockets` |
| Tools | `composer` 2 |

| Tag | sqlsrv / pdo_sqlsrv |
|---|---|
| `8.5-fpm-alpine`, `8.4-fpm-alpine`, `8.3-fpm-alpine` | 5.13.3 |
| `8.2-fpm-alpine` | 5.12.0 (5.13 requires PHP >= 8.3) |

- `TZ=Asia/Ho_Chi_Minh` and `tzdata` set the system time (php-fpm logs, `date`).
  PHP ignores `TZ`: set `date.timezone` yourself, otherwise PHP uses UTC (see [Using the images](#using-the-images)).
- `amd64` only: the bundled `msodbcsql18` package is the amd64 build.

### Node.js (`khgtrn/node`)

| Tool | Version | Install |
|---|---|---|
| pnpm | latest 12.x | standalone, `/opt/pnpm/bin` (on `PATH`) |
| bun / bunx | latest 1.x | standalone, `/usr/local/bin` |

- pnpm and bun are standalone binaries, not global npm packages; pnpm runs without Node.
- The pnpm store is per user: `~/.local/share/pnpm/store` (works for both `root` and `node`).
- Node 20 is end-of-life (April 2026); keep it only for legacy projects.

## Requirements

- Docker 23+ (BuildKit is required for `RUN --mount` in the PHP Dockerfiles)
- `make`
- `docker login` to Docker Hub before pushing

## Repository layout

```
|
|- Makefile                             # build / push / test targets
|- download_asset.sh                    # downloads php/asset/*
|- php
  |- asset/                             # offline build assets (sqlsrv, pdo_sqlsrv, msodbcsql18)
  |- <version>-fpm-alpine.Dockerfile
|-node
  |- <version>-trixie-slim.Dockerfile
|-test
  |- php-compose.yaml                   # one container per PHP image
  |- node-compose.yaml                  # one container per Node image
```

## Build

The PHP build reads `php/asset/` instead of downloading from PECL or Microsoft. Fetch the files once:

```sh
./download_asset.sh
```

Then:

```sh
make build-php-8.5      # one version: build-php-8.4 / 8.3 / 8.2
make build-php          # all PHP versions

make build-node-26      # one version: build-node-26 / 22 / 20
make build-node         # all Node versions
```

Every build uses `--pull`: a newer base image on Docker Hub is pulled, otherwise the local one and the layer cache are reused.

The cache does not know about package updates: if the base image is unchanged, the `apk`/`apt` fixes, `redis` from PECL and new pnpm 12.x / bun 1.x releases are not picked up. Rebuild every layer before a release or after a security fix:

```sh
make build-php FRESH=1
make build-node FRESH=1
```

To build under another Docker Hub account:

```sh
make build-php PHP_REPO=youruser/php
make build-node NODE_REPO=youruser/node
```

## Push

```sh
docker login
make push-php-8.5       # or: make push-php (all versions)
make push-node-26       # or: make push-node (all versions)
```

Push does not build. Run the matching `build-*` target first.

## Check the images

The test compose files start one container per version from the local images.
PHP runs `php-fpm`; Node runs `sleep infinity` so the container stays up for `exec`.

```sh
make up-php                         # or: make up-node
make ps-php                         # every service should be "Up"

make shell-php-8.5                  # interactive sh in the php85 container
make shell-php-8.2 CMD="php -v"     # run one command
make shell-node-26 CMD="pnpm -v"

make down-php                       # or: make down-node
```

Commands worth running:

```sh
# PHP
make shell-php-8.5 CMD="php -v"
make shell-php-8.5 CMD="php -m"                  # extension list
make shell-php-8.5 CMD="composer --version"
make shell-php-8.5 CMD="php -r 'print_r(PDO::getAvailableDrivers());'"
# expected drivers: sqlite, dblib, mysql, odbc, pgsql, sqlsrv

# Node
make shell-node-26 CMD="node -v"
make shell-node-26 CMD="pnpm -v"
make shell-node-26 CMD="bun -v"
```

Without make:

```sh
docker run --rm khgtrn/php:8.5-fpm-alpine php -m
docker run --rm khgtrn/node:24-trixie-slim sh -c 'node -v && pnpm -v && bun -v'
```

## Using the images

Set the PHP timezone in your own compose file by mounting an ini file into `conf.d`:

```ini
; php.ini
date.timezone = Asia/Ho_Chi_Minh
```

```yaml
services:
  php:
    image: khgtrn/php:8.5-fpm-alpine
    volumes:
      - ./php.ini:/usr/local/etc/php/conf.d/00-php.ini:ro
```

## Image size

`docker images` shows two columns:

- **CONTENT SIZE**: compressed layers, what is pulled and pushed; comparable to the size on Docker Hub.
- **DISK USAGE**: compressed layers plus the unpacked layers on disk. Layers shared between images are counted in each image; `docker system df` gives the real total.

Sizes measured on 2026-10-25 (`DISK USAGE`):

| Image | Size |
|---|---|
| `khgtrn/php:8.5-fpm-alpine` | 212 MB (content 56.5 MB) |
| `khgtrn/php:8.4-fpm-alpine` | 192 MB |
| `khgtrn/php:8.3-fpm-alpine` | 185 MB |
| `khgtrn/php:8.2-fpm-alpine` | 179 MB |
| `khgtrn/node:26-trixie-slim` | 602 MB (content 165 MB) |
| `khgtrn/node:24-trixie-slim` | 584 MB |
| `khgtrn/node:22-trixie-slim` | 580 MB |
| `khgtrn/node:20-trixie-slim` | 544 MB |

The Node images are larger than the base image mainly because of the bun (~103 MB) and pnpm (~61 MB) binaries.

## Updating versions

| What | Where |
|---|---|
| Add a PHP / Node version | Copy an existing Dockerfile to `php/<x.y>-fpm-alpine.Dockerfile` or `node/<n>-trixie-slim.Dockerfile`, change `FROM`, add the version to `PHP_VERSIONS` / `NODE_VERSIONS` in the `Makefile` and a service to `test/*-compose.yaml` |
| sqlsrv / pdo_sqlsrv | Add the `.tgz` files to `download_asset.sh`, run it, change `ARG SQLSRV_VERSION` in the Dockerfiles |
| msodbcsql18 | Get the new link from [Download ODBC Driver for SQL Server](https://learn.microsoft.com/sql/connect/odbc/download-odbc-driver-for-sql-server#download-for-linux-and-macos) (the URL changes with every release), update `download_asset.sh`, change `ARG MSODBC_VERSION` |
| pnpm / bun major | `ARG PNPM_MAJOR` / `ARG BUN_MAJOR` in `node/*.Dockerfile` |

