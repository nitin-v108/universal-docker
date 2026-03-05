#!/usr/bin/env bash
# Interactive script to add a new Laravel project to the Docker environment.
# Creates Nginx vhost, DB init entry, and prints hosts + .env instructions.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
NGINX_SITES="$ROOT/docker/nginx/sites"
MARIADB_INIT="$ROOT/docker/mariadb/init/01-create-databases.sql"
TEMPLATE="$NGINX_SITES/_template.conf"

echo "=== New Laravel Project ==="
read -rp "Project name (e.g. myapp): " PROJECT
read -rp "Database name (e.g. myapp_db) [${PROJECT}_db]: " DB_NAME
DB_NAME="${DB_NAME:-${PROJECT}_db}"

PROJECT_CONF="$NGINX_SITES/${PROJECT}.conf"
if [ -f "$PROJECT_CONF" ]; then
  echo "Error: $PROJECT_CONF already exists."
  exit 1
fi

# Nginx vhost from template
sed "s/PROJECTNAME/$PROJECT/g" "$TEMPLATE" > "$PROJECT_CONF"
echo "Created $PROJECT_CONF"

# Add database and grant to init script (if not already present)
if ! grep -q "CREATE DATABASE IF NOT EXISTS ${DB_NAME}" "$MARIADB_INIT"; then
  tmp=$(mktemp)
  while IFS= read -r line; do
    if [ "$line" = "FLUSH PRIVILEGES;" ]; then
      echo "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
      echo "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO 'laravel'@'%';"
    fi
    echo "$line"
  done < "$MARIADB_INIT" > "$tmp"
  mv "$tmp" "$MARIADB_INIT"
  echo "Added $DB_NAME to $MARIADB_INIT"
fi

# Supervisor: suggest manual add
echo ""
echo "Add a queue worker in docker/supervisor/supervisord.conf:"
echo ""
echo "[program:${PROJECT}-worker]"
echo "command=php /var/www/${PROJECT}/artisan queue:work --sleep=3 --tries=3"
echo "directory=/var/www/${PROJECT}"
echo "autostart=true"
echo "autorestart=true"
echo "user=www-data"
echo "stdout_logfile=/var/log/supervisor/${PROJECT}-worker.log"
echo "stderr_logfile=/var/log/supervisor/${PROJECT}-worker.err.log"
echo ""

echo "--- Hosts file ---"
echo "Add this line to your hosts file:"
echo "  127.0.0.1 ${PROJECT}.local"
echo "  Windows: C:\\Windows\\System32\\drivers\\etc\\hosts"
echo ""

echo "--- Laravel .env (inside projects/${PROJECT}) ---"
echo "DB_CONNECTION=mysql"
echo "DB_HOST=mariadb"
echo "DB_PORT=3306"
echo "DB_DATABASE=${DB_NAME}"
echo "DB_USERNAME=laravel"
echo "DB_PASSWORD=secret"
echo ""
echo "REDIS_HOST=redis"
echo "REDIS_PASSWORD=null"
echo "REDIS_PORT=6379"
echo ""

echo "Next steps:"
echo "  1. Create Laravel: docker compose run --rm php bash -c 'cd /var/www && composer create-project laravel/laravel ${PROJECT}'"
echo "  2. Or clone your repo into projects/${PROJECT}"
echo "  3. Add the above DB/REDIS vars to projects/${PROJECT}/.env"
echo "  4. Restart: docker compose restart nginx php"
echo "  5. Open http://${PROJECT}.local"
