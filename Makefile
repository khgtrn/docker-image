# make build-php            -> --pull, reuse cache when the base image is unchanged
# make build-php FRESH=1    -> rebuild every layer (picks up apk/apt/pecl/pnpm/bun updates)
BUILD_FLAGS = --pull $(if $(FRESH),--no-cache)

PHP_REPO ?= khgtrn/php
PHP_VERSIONS := 8.2 8.3 8.4 8.5
PHP_TEST_COMPOSE := test/php-compose.yaml

PHP_BUILDS := $(addprefix build-php-,$(PHP_VERSIONS))
PHP_PUSHES := $(addprefix push-php-,$(PHP_VERSIONS))
PHP_SHELLS := $(addprefix shell-php-,$(PHP_VERSIONS))

$(PHP_BUILDS): build-php-%:
	docker build $(BUILD_FLAGS) -f php/$*-fpm-alpine.Dockerfile -t $(PHP_REPO):$*-fpm-alpine php

$(PHP_PUSHES): push-php-%:
	docker push $(PHP_REPO):$*-fpm-alpine

build-php: $(PHP_BUILDS)

push-php: $(PHP_PUSHES)

up-php:
	docker compose -f $(PHP_TEST_COMPOSE) up -d

down-php:
	docker compose -f $(PHP_TEST_COMPOSE) down

ps-php:
	docker compose -f $(PHP_TEST_COMPOSE) ps

# make shell-php-8.5            -> sh in service php85
# make shell-php-8.5 CMD="php -v"
CMD ?= sh
$(PHP_SHELLS): shell-php-%:
	docker compose -f $(PHP_TEST_COMPOSE) exec php$(subst .,,$*) $(CMD)

.PHONY: build-php push-php up-php down-php ps-php $(PHP_BUILDS) $(PHP_PUSHES) $(PHP_SHELLS)

NODE_REPO ?= khgtrn/node
NODE_VERSIONS := 20 22 24 26
NODE_TEST_COMPOSE := test/node-compose.yaml

NODE_BUILDS := $(addprefix build-node-,$(NODE_VERSIONS))
NODE_PUSHES := $(addprefix push-node-,$(NODE_VERSIONS))
NODE_SHELLS := $(addprefix shell-node-,$(NODE_VERSIONS))

$(NODE_BUILDS): build-node-%:
	docker build $(BUILD_FLAGS) -f node/$*-trixie-slim.Dockerfile -t $(NODE_REPO):$*-trixie-slim node

$(NODE_PUSHES): push-node-%:
	docker push $(NODE_REPO):$*-trixie-slim

build-node: $(NODE_BUILDS)

push-node: $(NODE_PUSHES)

up-node:
	docker compose -f $(NODE_TEST_COMPOSE) up -d

down-node:
	docker compose -f $(NODE_TEST_COMPOSE) down

ps-node:
	docker compose -f $(NODE_TEST_COMPOSE) ps

# make shell-node-24 CMD="pnpm -v"
$(NODE_SHELLS): shell-node-%:
	docker compose -f $(NODE_TEST_COMPOSE) exec node$* $(CMD)

.PHONY: build-node push-node up-node down-node ps-node $(NODE_BUILDS) $(NODE_PUSHES) $(NODE_SHELLS)
