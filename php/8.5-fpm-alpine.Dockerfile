FROM php:8.5-fpm-alpine

ARG SQLSRV_VERSION=5.13.3
ARG MSODBC_VERSION=18.7.1.1-1

ENV TZ="Asia/Ho_Chi_Minh"

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Upgrade base packages to pick up Alpine security fixes before the official php image is rebuilt
RUN apk upgrade --no-cache \
 && apk add --no-cache tzdata \
 && install-php-extensions gd zip bcmath sockets mysqli pdo_mysql pdo_dblib odbc pdo_odbc pgsql pdo_pgsql redis

# ODBC driver + sqlsrv build from .tgz downloaded
# Mount asset/ only during build so the files do not stay in an image layer
RUN --mount=type=bind,source=asset,target=/tmp/asset \
    set -eux; \
    apk add --no-cache --allow-untrusted /tmp/asset/msodbcsql18_${MSODBC_VERSION}_amd64.apk unixodbc; \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS unixodbc-dev; \
    docker-php-source extract; \
    for ext in sqlsrv pdo_sqlsrv; do \
        mkdir -p /usr/src/php/ext/$ext; \
        tar -xzf /tmp/asset/${ext}-${SQLSRV_VERSION}.tgz -C /usr/src/php/ext/$ext --strip-components=1; \
    done; \
    docker-php-ext-install -j"$(nproc)" sqlsrv pdo_sqlsrv; \
    docker-php-source delete; \
    apk del .build-deps

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
