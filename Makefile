# Lions International WordPress theme - developer commands.
# Run `make help` for a list.

SHELL := /bin/bash
COMPOSE ?= docker compose
THEME_DIR := theme
THEME_IN_CONTAINER := /var/www/html/wp-content/themes/lions-theme
BIN_IN_CONTAINER := /opt/lions/bin

# Run a command inside the wordpress container, in the theme directory.
EXEC := $(COMPOSE) exec -T -w $(THEME_IN_CONTAINER) wordpress
EXEC_TTY := $(COMPOSE) exec -w $(THEME_IN_CONTAINER) wordpress

.DEFAULT_GOAL := help

.PHONY: help up down restart logs shell db-shell composer install wp lint test cs-fix build set-version i18n clean status

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

.env:
	cp .env.example .env
	@echo "Created .env from .env.example"

up: .env ## Build and start WordPress + MySQL (http://localhost:8080)
	$(COMPOSE) up -d --build
	@$(MAKE) --no-print-directory composer ARGS="install --no-interaction"
	@echo
	@echo "WordPress: http://localhost:$$(grep -E '^WORDPRESS_PORT=' .env | cut -d= -f2 || echo 8080)"
	@echo "Run 'make install' to complete the WordPress setup and seed demo content."

down: ## Stop containers (data is kept in volumes)
	$(COMPOSE) down

restart: ## Restart containers
	$(COMPOSE) restart

logs: ## Tail WordPress + database logs (and the PHP debug log)
	$(COMPOSE) logs -f --tail=100

shell: ## Shell inside the WordPress container (theme directory)
	$(EXEC_TTY) bash

db-shell: ## MySQL prompt
	$(COMPOSE) exec db sh -c 'mysql -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" "$$MYSQL_DATABASE"'

composer: ## Run Composer in the theme, e.g. make composer ARGS="require foo/bar"
	$(EXEC) composer $(or $(ARGS),install --no-interaction)

install: ## Complete WordPress setup + seed demo content (idempotent)
	$(COMPOSE) exec -T wordpress bash $(BIN_IN_CONTAINER)/wp-install.sh

wp: ## Run WP-CLI, e.g. make wp ARGS="plugin list"
	$(COMPOSE) exec -T wordpress wp --allow-root --path=/var/www/html $(ARGS)

lint: ## PHP syntax, Composer validation, PHPCS (WordPress standards), Twig syntax
	$(EXEC) composer validate --strict --no-check-publish
	$(EXEC) composer run lint:php
	$(EXEC) composer run lint:phpcs
	$(EXEC) php $(BIN_IN_CONTAINER)/twig-lint.php $(THEME_IN_CONTAINER)

test: ## PHPStan static analysis + theme structure validation + Docker Compose config
	$(EXEC) composer run analyse
	$(EXEC) sh $(BIN_IN_CONTAINER)/validate-theme.sh $(THEME_IN_CONTAINER)
	$(COMPOSE) config -q && echo "docker-compose.yml OK"

cs-fix: ## Auto-fix coding standard violations (phpcbf)
	$(EXEC) sh -c 'vendor/bin/phpcbf || true'

build: ## Build the production package build/lions-theme.zip
	bash bin/build.sh

set-version: ## Write a version into style.css + Theme::VERSION (make set-version VERSION=1.0.4)
	@sh bin/set-version.sh "$(VERSION)" $(THEME_DIR)

i18n: ## Compile languages/*.po into the *.mo files WordPress reads (run after editing a .po)
	@sh bin/compile-translations.sh $(THEME_DIR)

clean: ## Remove build output, caches and vendor/ (containers + volumes untouched)
	rm -rf build $(THEME_DIR)/vendor $(THEME_DIR)/.phpcs-cache $(THEME_DIR)/.phpstan-cache

status: ## Show container status
	$(COMPOSE) ps
