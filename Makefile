# Laravel Docker - Makefile
# Usage: make [target]; for project-specific: make art p=project1 c="migrate"
# Run from repo root: cd /path/to/laravel-docker-env && make <target>

ROOT := $(shell cd "$(dirname $(firstword $(MAKEFILE_LIST)))" && pwd)

.PHONY: up down restart rebuild ps logs art composer npm shell fresh db-create db-backup db-restore mysql new-project clear-cache permissions fix-storage-permissions shell-ttm help

# Default project for art/composer/npm/shell/fresh
p ?= project1
c ?=

# Show available commands
help:
	@echo "Usage: make [target]  (default project: p=project1)"
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:' Makefile | grep -v '^#' | head -40 | cut -d: -f1 | sed 's/^/  /'

# Container management
up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

rebuild:
	docker compose down
	docker compose build --no-cache
	docker compose up -d

ps:
	docker compose ps

logs:
	docker compose logs -f

# Project-specific (run inside PHP container)
art:
	docker compose exec php bash -c "cd /var/www/$(p) && php artisan $(c)"

composer:
	docker compose exec php bash -c "cd /var/www/$(p) && composer $(c)"

npm:
	docker compose exec php bash -c "cd /var/www/$(p) && npm $(c)"

shell:
	docker compose exec php bash -c "cd /var/www/$(p) && exec bash"

# TTM (PHP 5.6) – shell into php56 container
shell-ttm:
	docker compose exec php56 bash -c "cd /var/www/ttm && exec bash"

# TTM: make upload/temp dirs writable by www-data (fix "Permission denied" on timesheet import)
permissions-ttm:
	docker compose exec php56 bash -c "mkdir -p /var/www/ttm/TTM_import_Timesheets /var/www/ttm/temp_timesheet /var/www/ttm/pdfimage && chown -R www-data:www-data /var/www/ttm/TTM_import_Timesheets /var/www/ttm/temp_timesheet /var/www/ttm/pdfimage"

fresh:
	docker compose exec php bash -c "cd /var/www/$(p) && php artisan migrate:fresh --seed"

# Database
db-create:
	@read -p "Database name (e.g. myapp_db): " dbname; \
	echo "CREATE DATABASE IF NOT EXISTS $$dbname CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; GRANT ALL ON $$dbname.* TO 'laravel'@'%%'; FLUSH PRIVILEGES;" | docker compose exec -T mariadb mysql -uroot -p$${MYSQL_ROOT_PASSWORD:-root}

db-backup:
	docker compose exec mariadb sh -c 'mysqldump -uroot -p$$MYSQL_ROOT_PASSWORD --all-databases' > backup_$$(date +%Y%m%d_%H%M%S).sql

db-restore:
	@echo "Usage: cat backup.sql | docker compose exec -T mariadb mysql -uroot -p<rootpass>"

mysql:
	docker compose exec mariadb mysql -ularavel -psecret

# Utility
new-project:
	./scripts/new-project.sh

clear-cache:
	docker compose exec php bash -c "for d in /var/www/*/; do [ -f \"$$d/artisan\" ] && (cd \"$$d\" && php artisan cache:clear config:clear view:clear) || true; done"

permissions:
	docker compose exec php bash -c "for d in /var/www/*/; do [ -d \"$$d/storage\" ] && chown -R www-data:www-data \"$$d/storage\" \"$$d/bootstrap/cache\" 2>/dev/null || true; done"

# Fix ownership of storage/logs so you can edit/delete files (Docker creates them as root)
# No sudo needed – uses a temp container to chown the mounted volume
fix-storage-permissions:
	@echo "Fixing storage/logs ownership to current user ($$(id -u):$$(id -g))..."
	@docker run --rm -v "$$(pwd)/storage/logs:/logs" alpine chown -R $$(id -u):$$(id -g) /logs
	@echo "Done. You can now edit/delete files in storage/logs/"

# Paynbill: also make public/ writable so uploads (e.g. signature, timesheets) work
permissions-paynbill:
	docker compose exec php bash -c "chown -R www-data:www-data /var/www/paynbill/storage /var/www/paynbill/bootstrap/cache /var/www/paynbill/public 2>/dev/null || true"

# Paynbill: run client DB schema migration (mysql/mariadb CLI in PHP container via shared socket)
migratedbschema-paynbill:
	docker compose exec php bash -c "cd /var/www/paynbill && php artisan migratedbschema:update"

# Credit Control API (Node 24 + PM2 on port 8085)
cc-build:
	docker compose build --no-cache credit-control

cc-logs:
	docker compose logs -f credit-control

cc-shell:
	docker compose exec credit-control sh -c "cd /var/www/credit-control && exec sh"

cc-pm2-status:
	docker compose exec credit-control bash -c '. /root/.nvm/nvm.sh && nvm use 24 && cd /var/www/credit-control && pm2 status'

cc-pm2-restart:
	docker compose exec credit-control bash -c '. /root/.nvm/nvm.sh && nvm use 24 && cd /var/www/credit-control && pm2 restart ecosystem.config.cjs --env development'

# Rebuild credit-control (npm run build:dev) then restart PM2 – use after source changes
cc-rebuild:
	docker compose exec credit-control bash -c '. /root/.nvm/nvm.sh && nvm use 24 && cd /var/www/credit-control && npm run build:dev && pm2 restart ecosystem.config.cjs --env development'

# Create ccDevAdm user if missing (init runs only when MongoDB data dir was empty on first start)
cc-mongo-create-user:
	@sh $(ROOT)/scripts/cc-mongo-create-ccDevAdm.sh

# MongoDB shell (authenticated as root so you can run show users, db.getUsers(), etc.)
cc-mongo-shell:
	docker compose exec mongodb mongosh --username root --password "$$(grep '^MONGO_ROOT_PASSWORD=' .env 2>/dev/null | sed 's/^[^=]*=//' | tr -d '\r' || echo 'root')" --authenticationDatabase admin

# Restore databases from mongodump: put dump in storage/mongodb-restore/ then run this
cc-mongo-restore:
	@sh $(ROOT)/scripts/cc-mongo-restore.sh

# Reset MongoDB data (fixes "SCRAM storedKey mismatch" when MONGO_ROOT_PASSWORD changed)
# Stops mongodb, wipes storage/mongodb via container (no sudo), starts mongodb for fresh init
cc-mongo-reset:
	docker compose stop mongodb
	docker run --rm -v "$$(pwd)/storage/mongodb:/wipe" alpine sh -c "rm -rf /wipe/* /wipe/.[!.]* 2>/dev/null"
	docker compose up -d mongodb
	@echo "MongoDB reset. Wait for healthy, then: docker compose up -d credit-control"
