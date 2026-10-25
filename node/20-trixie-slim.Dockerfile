FROM node:20-trixie-slim AS tools

ARG PNPM_MAJOR=12
ARG BUN_MAJOR=1

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl openssl unzip

# Standalone installers; the major is resolved to its latest release
ENV PNPM_HOME=/opt/pnpm BUN_INSTALL=/opt/bun SHELL=/bin/bash
RUN curl -fsSL https://get.pnpm.io/install.sh | env PNPM_VERSION=${PNPM_MAJOR} sh - \
 && rm -rf /opt/pnpm/store
RUN BUN_VERSION="$(npm view "bun@${BUN_MAJOR}" version --json | node -p '[].concat(JSON.parse(require("fs").readFileSync(0))).pop()')" \
 && curl -fsSL https://bun.com/install | bash -s "bun-v${BUN_VERSION}"

FROM node:20-trixie-slim

# PNPM_HOME is left unset so each user gets its own store under ~/.local/share/pnpm
ENV PATH=/opt/pnpm/bin:$PATH

COPY --from=tools /opt/pnpm /opt/pnpm
COPY --from=tools /opt/bun/bin/bun /usr/local/bin/bun
RUN ln -s bun /usr/local/bin/bunx
