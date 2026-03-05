#!/usr/bin/env bash
# Run Laravel artisan in a specific project context inside the PHP container.
# Usage: ./scripts/artisan.sh project1 migrate
#        ./scripts/artisan.sh project2 queue:work

set -e
PROJECT="${1:?Usage: $0 <project_name> <artisan_command...>}"
shift
docker compose exec php bash -c "cd /var/www/$PROJECT && php artisan $*"
