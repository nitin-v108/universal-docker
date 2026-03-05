#!/usr/bin/env bash
# Run Composer in a specific project context inside the PHP container.
# Usage: ./scripts/composer.sh project1 require package/name
#        ./scripts/composer.sh project2 install

set -e
PROJECT="${1:?Usage: $0 <project_name> <composer_command...>}"
shift
docker compose exec php bash -c "cd /var/www/$PROJECT && composer $*"
