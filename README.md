# Laravel Docker Development Environment

**Production-ready Docker boilerplate for Laravel, Node.js, and React development on Windows 11 with WSL2.**

One Nginx, one PHP 8.3-FPM, one MariaDB, one Redis, one MongoDB, Node.js (Credit Control), and multiple projects in `./projects/`.

---

## Quick Start

```bash
# Clone and setup (in WSL2)
git clone <REPO_URL> laravel-docker-env
cd laravel-docker-env
./scripts/first-time-setup.sh

# Start containers
make up

# Add a project
make new-project
```

**New to this setup?** → [Complete Setup Guide (docs/SETUP.md)](docs/SETUP.md)

---

## Documentation

- **[docs/SETUP.md](docs/SETUP.md)** – First-time installation, WSL2, Docker Desktop
- **[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)** – How to contribute
- **[docs/CHANGELOG.md](docs/CHANGELOG.md)** – Version history
- **[docs/GIT_SETUP.md](docs/GIT_SETUP.md)** – Git and boilerplate updates

---

## Stack

| Component | Version |
|-----------|---------|
| Base OS (containers) | Ubuntu / Alpine as per image |
| Nginx | 1.26 |
| PHP (Laravel, paynbill, etc.) | 8.3 LTS (PHP-FPM) |
| PHP (TTM legacy only) | 5.6 (PHP-FPM, separate container) |
| MariaDB | 10.11 |
| Redis | 8.0 (Alpine) |
| Node.js | 20 LTS (in PHP container, for Laravel Mix/Vite) |

PHP extensions: gd, imagick, pdo_mysql, redis, mbstring, xml, curl, zip, bcmath, intl, opcache, exif, pcntl, soap, xsl, gmp.

---

## Prerequisites

- **Docker Desktop** (Windows/Mac) or Docker Engine + Docker Compose v2
- **Windows 11**: Use **WSL2** backend for Docker Desktop (recommended); run the repo from the WSL filesystem (e.g. `~/projects/laravel-docker-env`) for best compatibility and performance.
- **Git** (for cloning and scripts)

---

## Performance (local dev)

If the site feels slow, see **[docs/PERFORMANCE.md](docs/PERFORMANCE.md)**. Quick wins: use **Redis** for cache/session (already set for paynbill), keep **Xdebug off**, and on Windows consider moving the project into **WSL2** and excluding the project folder from **Windows Defender** real-time scanning.

---

## Installation

1. **Clone or copy** this repo and `cd` into it:
   ```bash
   cd laravel-docker-env
   ```

2. **Create `.env`** (if not present):
   ```bash
   cp .env.example .env
   ```
   Edit `.env` to change `MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD`, etc. if needed.

3. **Start containers**:
   ```bash
   docker compose up -d
   ```
   First run will build the PHP image (a few minutes).

4. **Check status**:
   ```bash
   docker compose ps
   ```
   All services should be “healthy” or “running”.

---

## Starting / Stopping

- **Start:** `docker compose up -d` or `make up`
- **Stop:** `docker compose down` or `make down`
- **Logs:** `docker compose logs -f` or `make logs`
- **Restart:** `docker compose restart` or `make restart`
- **Rebuild PHP image:** `make rebuild`

---

## Adding New Laravel Projects

### Option A: Using the script (recommended)

```bash
./scripts/new-project.sh
```

You will be prompted for:

- **Project name** (e.g. `myapp`) → site will be `http://myapp.local`
- **Database name** (e.g. `myapp_db`)

The script will:

- Create `docker/nginx/sites/myapp.conf` from the template
- Add the new database to `docker/mariadb/init/01-create-databases.sql`
- Print instructions for hosts file and Laravel `.env`

Then:

1. **Create or clone Laravel** in `projects/<name>/`:
   ```bash
   docker compose run --rm php bash -c "cd /var/www && composer create-project laravel/laravel myapp"
   ```
   Or clone your repo into `projects/myapp/`.

2. **Configure Laravel `.env`** in `projects/myapp/.env` (see [Laravel .env](#laravel-env-database--redis) below).

3. **Add a queue worker** (optional): edit `docker/supervisor/supervisord.conf` and add a block like:
   ```ini
   [program:myapp-worker]
   command=php /var/www/myapp/artisan queue:work --sleep=3 --tries=3
   directory=/var/www/myapp
   autostart=true
   autorestart=true
   user=www-data
   stdout_logfile=/var/log/supervisor/myapp-worker.log
   stderr_logfile=/var/log/supervisor/myapp-worker.err.log
   ```

4. **Restart Nginx and PHP** (so new vhost and supervisor are loaded):
   ```bash
   docker compose restart nginx php
   ```

5. **Run migrations**:
   ```bash
   make art p=myapp c="migrate"
   # or
   ./scripts/artisan.sh myapp migrate
   ```

### Option B: Manual steps

- Copy `docker/nginx/sites/_template.conf` to `docker/nginx/sites/<project>.conf` and replace `PROJECTNAME` with your project name.
- Add `CREATE DATABASE ...` and `GRANT ...` to `docker/mariadb/init/01-create-databases.sql`.
- Restart containers after creating the Laravel app and configuring `.env`.

---

## Running TTM (PHP 5.6 legacy app)

TTM is a **core PHP 5.6** project (not Laravel). This stack runs it with a **separate PHP 5.6 container** (`php56`) so that Laravel and other PHP 8.3 projects are unchanged.

1. **Clone TTM** into `projects/ttm/` (you already have it).

2. **Database config for Docker**  
   The `php56` container sets `TTM_MYSQL_HOST=mariadb`, and TTM's `include/globalconfig.php` (Local) uses that so the app talks to the MariaDB service. No manual edit needed. The database `sjethwa_ttmdev` and user `ttmdev` are already created by `docker/mariadb/init/01-create-databases.sql`.

3. **Hosts file**  
   Add:
   ```
   127.0.0.1 dev.integra-paybill.co.uk
   ```
   (On Windows: `C:\Windows\System32\drivers\etc\hosts` as Administrator.)

4. **Build and start** (first time or after adding php56):
   ```bash
   docker compose build php56 && docker compose up -d
   ```
   Or full rebuild: `make rebuild`.

5. **Open the app:**  
   **http://dev.integra-paybill.co.uk**

**Which container runs what**

- **php** (PHP 8.3): paynbill, otm-laravel, user-management, and all other Laravel projects.
- **php56** (PHP 5.6): only TTM (`projects/ttm`).  
Nginx sends `dev.integra-paybill.co.uk` to `php56`; all other vhosts use `php`.

**Useful commands**

- Shell into PHP 5.6 container: `docker compose exec php56 bash`
- Rebuild only PHP 5.6: `docker compose build --no-cache php56 && docker compose up -d php56`
- Restart Nginx after changing `docker/nginx/sites/ttm.conf`: `docker compose restart nginx`
- **Timesheet import "Permission denied"**: run `make permissions-ttm` (after rebuilding php56, the container’s www-data uses UID 1000 so you usually don’t need this).

**Copy/paste from Windows 11 and Zone.Identifier**

- The **php56** image sets www-data to **UID 1000** (same as the main PHP image), so files you create or copy into `TTM_import_Timesheets/` from WSL or Windows stay writable by both you and the web server. You should be able to copy/paste into that folder without running `make permissions-ttm`.
- If you **can’t copy/paste** into the folder after having run `make permissions-ttm` earlier, the dirs may be owned by the old www-data (UID 33). Rebuild php56 (`docker compose build --no-cache php56 && docker compose up -d php56`) so www-data is 1000, then run `make permissions-ttm` again so ownership is 1000 and you keep write access.
- **`1page.pdf:Zone.Identifier`** (and similar): Windows marks files from the internet or another PC with a “zone” alternate data stream. On WSL/Linux that can show up as a separate file named `filename:Zone.Identifier`. The timesheet import only looks for `*.pdf`, so it won’t process these; they’re harmless but can be removed. To avoid creating them: in Windows, right‑click the file → **Properties** → if you see **Unblock**, check it and apply before copying into the project. To remove existing ones in WSL: `find projects/ttm -name '*:Zone.Identifier' -delete`.

---

## Windows Hosts File

So that `http://project1.local` and `http://project2.local` work on your machine:

1. Open **hosts** as Administrator:
   - Path: `C:\Windows\System32\drivers\etc\hosts`
2. Add lines:
   ```
   127.0.0.1 project1.local
   127.0.0.1 project2.local
   127.0.0.1 myapp.local
   ```
   (Add one line per project.)

3. Save and flush DNS if needed:
   ```powershell
   ipconfig /flushdns
   ```

---

## Laravel .env (Database & Redis)

Inside each project (e.g. `projects/project1/.env`), use the **service names** as hosts (not `localhost`):

```env
DB_CONNECTION=mysql
DB_HOST=mariadb
DB_PORT=3306
DB_DATABASE=project1_db
DB_USERNAME=laravel
DB_PASSWORD=secret

REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379
```

Values must match your `.env` in the repo root (`MYSQL_USER`, `MYSQL_PASSWORD`). Database names must match those created in `docker/mariadb/init/01-create-databases.sql`.

---

## Common Commands

| Task | Command |
|------|---------|
| Start | `make up` or `docker compose up -d` |
| Stop | `make down` or `docker compose down` |
| Artisan | `make art p=project1 c="migrate"` or `./scripts/artisan.sh project1 migrate` |
| Composer | `make composer p=project1 c="require package/name"` or `./scripts/composer.sh project1 require package/name` |
| NPM | `make npm p=project1 c="run dev"` |
| Shell (project dir) | `make shell p=project1` |
| Migrate fresh + seed | `make fresh p=project1` |
| MySQL CLI | `make mysql` (uses laravel user) |
| Clear all Laravel caches | `make clear-cache` |
| Fix storage permissions | `make permissions` |
| Fix storage + public (paynbill uploads) | `make permissions-paynbill` |
| Paynbill: client DB schema migration | `make migratedbschema-paynbill` |
| TTM (PHP 5.6) shell | `make shell-ttm` |
| TTM: fix timesheet import dir permissions | `make permissions-ttm` |
| New project wizard | `./scripts/new-project.sh` |

---

## Accessing Services

| Service | URL / Connection |
|---------|-------------------|
| Project 1 | http://project1.local |
| Project 2 | http://project2.local |
| TTM (PHP 5.6) | http://ttm.local or http://dev.ttm.local |
| Default (project list) | http://localhost |
| MariaDB | `localhost:3306` (user: `laravel`, password from `.env`) |
| Redis | `localhost:6379` |

From **inside** containers (e.g. Laravel app), use hostnames **mariadb** and **redis**.

---

## File Permissions

The PHP container runs PHP-FPM and queue workers as **www-data** (UID/GID 1000). If you see permission errors in Laravel (storage, cache):

```bash
make permissions
```

This runs `chown -R www-data:www-data` on each project’s `storage` and `bootstrap/cache`. On Windows with Docker Desktop, permission issues are less common but this can still help when using WSL2 volumes.

---

## Configuration (large PHP + MySQL applications)

Defaults are tuned for large apps (big queries, imports, long-running scripts):

| Component | File | Notable settings |
|-----------|------|-------------------|
| MariaDB | `docker/mariadb/my.cnf` | `max_allowed_packet = 128M`, `innodb_buffer_pool_size = 512M`, `wait_timeout = 600`, larger temp/buffer sizes |
| PHP | `docker/php/php.ini` | `memory_limit = 768M`, `max_execution_time = 600`, `upload_max_filesize = 256M`, `post_max_size = 256M` |
| PHP-FPM | `docker/php/php-fpm.conf` | `request_terminate_timeout = 600` |

After editing any of these, restart the relevant service: `docker compose restart mariadb` or `docker compose restart php`.

---

## Xdebug (Cursor / VS Code)

- **Default:** Xdebug is **off** (`XDEBUG_MODE=off` in `.env`) for better performance.
- **Enable:** In the repo root `.env` set:
  ```env
  XDEBUG_MODE=debug
  XDEBUG_CLIENT_HOST=host.docker.internal
  XDEBUG_START_WITH_REQUEST=yes
  ```
  Then restart PHP: `docker compose restart php`.

- **Cursor / VS Code:** Install the **PHP Debug** extension and add a launch config that listens on port **9003** (Xdebug 3). Use “Listen for Xdebug” and open your app in the browser or run a script; the debugger will attach.

---

## Troubleshooting

### Containers won’t start

- Run `docker compose config` to validate `docker-compose.yml`.
- Run `docker compose build --no-cache` then `docker compose up -d` to rebuild the PHP image.
- Check `docker compose logs nginx php mariadb redis` for errors.

### 502 Bad Gateway

- PHP container might not be ready: `docker compose ps` and ensure `php` is healthy.
- Check Nginx error log: `docker compose exec nginx cat /var/log/nginx/error.log`.
- Ensure the project path in Nginx (e.g. `/var/www/project1/public`) exists and contains `index.php`.

### Database connection refused

- Ensure MariaDB is healthy: `docker compose ps`.
- From the host: `docker compose exec mariadb mysql -ularavel -psecret -e "SELECT 1"`.
- In Laravel `.env`, use `DB_HOST=mariadb` (not `localhost`).

### Error 1153: Got a packet bigger than 'max_allowed_packet'

- The stack is pre-tuned for large apps: `docker/mariadb/my.cnf` sets `max_allowed_packet = 128M`, and PHP allows larger uploads and longer runtimes. Restart containers so changes apply: `docker compose restart mariadb php`.
- If you still hit the limit, increase `max_allowed_packet` in `docker/mariadb/my.cnf` (and in `[client]` / `[mysql]`), then restart MariaDB.

### MariaDB won't start: "File ./ib_logfile0 was not found"

This happens if InnoDB redo log files were removed while the data directory still has existing data (e.g. after changing `innodb_log_file_size`). The repo's `my.cnf` may already have `innodb_force_recovery = 1` set so the server can start.

1. **Start the stack** (with `innodb_force_recovery = 1` in `docker/mariadb/my.cnf`):  
   `docker compose up -d`
2. **Take a full backup** (from repo root; use your actual root password from `.env`):  
   `docker compose exec mariadb mysqldump -uroot -p"${MYSQL_ROOT_PASSWORD:-root}" --all-databases --single-transaction --routines --triggers > backup_before_recovery_$(date +%Y%m%d).sql`
3. **Stop containers:**  
   `docker compose down`
4. **Remove `innodb_force_recovery = 1`** from `docker/mariadb/my.cnf` (delete or comment out that line).
5. **Wipe the MariaDB data directory** so it can re-initialise and create new log files:  
   `sudo rm -rf storage/mysql/*`  
   (Or move it aside: `mv storage/mysql storage/mysql.old` and `mkdir -p storage/mysql`.)
6. **Start again** (init scripts will recreate databases and users):  
   `docker compose up -d`
7. **Restore the backup:**  
   `docker compose exec -T mariadb mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-root}" < backup_before_recovery_YYYYMMDD.sql`

After that, leave `innodb_log_file_size` at 64M unless you follow the proper procedure: clean shutdown → remove log files → then start with the new size.

### Queue workers not running

- Supervisor runs inside the PHP container. Add a `[program:projectname-worker]` block in `docker/supervisor/supervisord.conf` and restart: `docker compose restart php`.
- Check logs: `docker compose exec php cat /var/log/supervisor/project1-worker.log`.

### Git "dubious ownership" when running Composer in the PHP container

When you run `composer update` or `composer install` **inside the container** (`docker compose exec php bash -c "cd /var/www/otm-laravel && composer update"`), Git runs inside the container too. The repo is bind-mounted from the host, so Git sees different ownership and can refuse with "detected dubious ownership". The PHP image is set up so Git trusts all directories (`safe.directory '*'`). If you use an image built before that change, run once inside the container:

```bash
docker compose exec php git config --global --add safe.directory '*'
```

Then re-run your Composer command. To bake this into the image for new containers: `make rebuild` or `docker compose build --no-cache php && docker compose up -d`.

### Windows / WSL2 performance

- Prefer **WSL2** backend for Docker Desktop.
- Store the repo in the WSL filesystem (e.g. `~/projects/laravel-docker-env`) for better I/O than Windows mounts.
- If you must use a Windows path, consider `docker compose run` for one-off commands to avoid slow shared volumes for long-running processes.

---

## Layout Overview

```
laravel-docker-env/
├── docker/
│   ├── nginx/          # Nginx config and vhosts
│   ├── php/            # PHP Dockerfile, php.ini, php-fpm, xdebug
│   ├── mariadb/        # my.cnf and init SQL
│   ├── redis/          # redis.conf
│   └── supervisor/     # supervisord.conf (PHP-FPM + queue workers)
├── projects/           # Laravel apps: project1, project2, ...
├── scripts/            # new-project.sh, artisan.sh, composer.sh
├── storage/            # mysql data, redis data, logs (gitignored)
├── docker-compose.yml
├── .env / .env.example
├── Makefile
└── README.md
```

---

## License

Use and adapt as needed for your projects.
