SHELL := /bin/bash
CONTAINER_MANAGER := docker
PROJECT_SOURCE := ./
DATABASE_URL := mysql://app:app@mysql:3306/shopware

SHOPWARE_CLI := bin/console
SHOPWARE_APP_ENV ?= dev
SHOPWARE_APP_URL ?= http://localhost:8080
SHOPWARE_THEME_NAME := Storefront
SHOPWARE_ADMIN_USERNAME := admin
SHOPWARE_ADMIN_PASSWORD := shopware

MAILHOG_APP_URL ?= http://localhost:8025

SHOPWARE_APP_ENV ?= dev
SHOPWARE_CLI ?= bin/console
SHOPWARE_THEME_NAME ?= Default

COMPOSER_BIN ?= /usr/bin/composer
COMPOSER_VENDOR_BIN ?= vendor/bin
COMPOSER_INSTALL_OPTIONS ?= --no-interaction --optimize-autoloader --no-scripts

ifeq (, $(shell which docker-compose))
  DOCKER_COMPOSE :=
  PHP_RUN := php
  PHP_EXEC := php
else
  DOCKER_COMPOSE := USER_ID=$$(id -u) docker-compose
  PHP_RUN := $(DOCKER_COMPOSE) run -T --rm php-fpm php
  PHP_EXEC := $(DOCKER_COMPOSE) exec -T php-fpm php
  MYSQL_RUN := $(DOCKER_COMPOSE) exec -T mysql mysql -uroot -proot shopware
endif

.PHONY: vendor
vendor: composer/install-development

# Build local environment
.PHONY: build
build:
	$(DOCKER_COMPOSE) build

# Start local environment
.PHONY: start
start: build
	$(DOCKER_COMPOSE) rm -f php-fpm \
	&& $(DOCKER_COMPOSE) up -d --remove-orphans

# Stop local environment
.PHONY: stop
stop:
	$(DOCKER_COMPOSE) stop

.PHONY: mysql/wait
mysql/wait:
	# sleep is needed to wait for mysql (!)
	$(DOCKER_COMPOSE) exec -T -e DATABASE_URL="" -e APP_ENV=$(SHOPWARE_APP_ENV) -e DATABASE-URL=$(DATABASE_URL) php-fpm bash -c 'while ! mysqladmin status -h mysql -uroot -proot; do sleep 1; done'

.PHONY: info/services
info/services:
	printf "Start browsing:\n" \
	&& printf "  Shopware storefront: $(SHOPWARE_APP_URL)\n" \
	&& printf "  Shopware backend: $(SHOPWARE_APP_URL)/admin (username=$(SHOPWARE_DB_USERNAME) and password=$(SHOPWARE_DB_PASSWORD))\n" \
	&& printf "  Mailhog: $(MAILHOG_APP_URL)\n"

.PHONY: init
init: shopware/download/production start vendor mysql/wait shopware/system/setup shopware/system/install shopware/build/js shopware/theme/activate shopware/framework/demodata info/services

.PHONY: down
down:
	$(DOCKER_COMPOSE) down -v

.PHONY: shell
shell:
	$(DOCKER_COMPOSE) exec php-fpm bash

.PHONY: %/analyze
%/analyze:
	$(PHP_RUN) /usr/bin/composer run-script -d . $(@D)

# creates docker-compose.override.yml from docker-compose.override.yml.dist if CI env variable is not set
docker-compose.override.yml:
	@if [ -z "$$CI" ]; then \
  		cp docker-compose.override.yml.dist docker-compose.override.yml; \
	fi

.PHONY: shopware/download/production
shopware/download/production:
	curl -L $$(curl -s 'https://api.github.com/repos/shopware/production/releases/latest'|jq -r '.tarball_url') -o shopware.tar.gz;
	tar xzf shopware.tar.gz;
	rm -r $$(ls|grep 'shopware-')/README.md $$(ls|grep 'shopware-')/.gitlab* $$(ls|grep 'shopware-')/.github $$(ls|grep 'shopware-')/.dockerignore $$(ls|grep 'shopware-')/Dockerfile $$(ls|grep 'shopware-')/docker-compose.yml;
	cp -r $$(ls|grep 'shopware-')/. .;
	rm -r $$(ls|grep 'shopware-');
	rm shopware.tar.gz;
	$(DOCKER_COMPOSE) run -T --rm php-fpm composer config description 'Shopware 6 Project Playground';

.PHONY: shopware/system/setup
shopware/system/setup:
	$(DOCKER_COMPOSE) exec -T \
	-e APP_ENV=$(SHOPWARE_APP_ENV) \
	-e DATABASE-URL=$(DATABASE_URL) \
	php-fpm $(SHOPWARE_CLI) system:setup --database-url="$(DATABASE_URL)" -n --force

.PHONY: shopware/system/install
shopware/system/install:
	$(PHP_EXEC) $(SHOPWARE_CLI) system:install --drop-database --create-database --basic-setup --no-assign-theme --skip-jwt-keys-generation --force

.PHONY: shopware/framework/demodata
shopware/framework/demodata:
	$(DOCKER_COMPOSE) exec -T -e APP_ENV=prod php-fpm $(SHOPWARE_CLI) framework:demodata;
	$(PHP_EXEC) $(SHOPWARE_CLI) dal:refresh:index;
	$(PHP_EXEC) $(SHOPWARE_CLI) ca:cl;

.PHONY: shopware/plugin/refresh
shopware/plugin/refresh:
	$(PHP_EXEC) $(SHOPWARE_CLI) plugin:refresh > /dev/null

.PHONY: shopware/plugin/sync
shopware/plugin/sync: shopware/plugin/refresh
	$(PHP_EXEC) $(SHOPWARE_CLI) plugin:sync

.PHONY: shopware/config/sync
shopware/config/sync:
	$(PHP_EXEC) $(SHOPWARE_CLI) config:sync

.PHONY: shopware/build/js
shopware/build/js:
	$(DOCKER_COMPOSE) exec -T php-fpm bin/build-js.sh

.PHONY: shopware/theme/activate
shopware/theme/activate:
	printf "\n\nActivating the $(SHOPWARE_THEME_NAME):\n\n" \
	&& $(PHP_EXEC) $(SHOPWARE_CLI) theme:change $(SHOPWARE_THEME_NAME) --all --no-interaction

.PHONY: composer/validate
composer/validate:
	$(PHP_RUN) $(COMPOSER_BIN) validate --working-dir=$(PROJECT_SOURCE) --no-check-all

.PHONY: composer/auth/%s
composer/auth/%s:
	$(PHP_RUN) $(COMPOSER_BIN) config --working-dir=$(PROJECT_SOURCE) --auth $(@F) $(COMPOSER_USERNAME) $(COMPOSER_TOKEN)

.PHONY: composer/install-development
composer/install-development: composer/validate
	$(PHP_RUN) $(COMPOSER_BIN) install --working-dir=$(PROJECT_SOURCE) $(COMPOSER_INSTALL_OPTIONS)

.PHONY: composer/install-production
composer/install-production: composer/validate
	$(PHP_RUN) $(COMPOSER_BIN) install --working-dir=$(PROJECT_SOURCE) $(COMPOSER_INSTALL_OPTIONS) --no-dev
