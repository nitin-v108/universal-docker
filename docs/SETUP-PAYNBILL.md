# Pay & Bill (paynbill) – Docker setup steps

Follow these in order after cloning the project into `projects/paynbill/` and adding `.env`.

---

## Step 1: Update Laravel `.env` for Docker

In **`projects/paynbill/.env`** set hosts to Docker service names (not `localhost`):

- **DB_HOST** → `mariadb`
- **REDIS_HOST** → `redis`
- **APP_URL** → `http://paynbill.local` or `http://dev.paynbill.local` (must match the URL you’ll use in the browser)

Leave `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD` as they are (`ipb_system`, `u_system`, `Ipb@Syst3m`); the database and user are created by the Docker MariaDB init.

---

## Step 2: Add hosts file entry (Windows)

Open **C:\Windows\System32\drivers\etc\hosts** as Administrator and add:

```
127.0.0.1 paynbill.local
127.0.0.1 dev.paynbill.local
```

Save, then (optional) flush DNS: `ipconfig /flushdns`

---

## Step 3: Start or restart containers

From **`laravel-docker-env`** (repo root):

```bash
docker compose up -d
```

If containers were already running after adding paynbill’s Nginx config:

```bash
docker compose restart nginx php
```

---

## Step 4: Ensure database and user exist (MariaDB)

The init script creates `ipb_system`, `ipb_emails` and users `u_system`, `u_emails` **only on first-ever MariaDB init** (when the MySQL data volume is created).

- **If this is a fresh Docker setup**  
  You’re fine: start with Step 3; the init script will run.

- **If you already had MariaDB running before paynbill was added**  
  Run the SQL once manually:

```bash
docker compose exec mariadb mysql -uroot -proot -e "
CREATE DATABASE IF NOT EXISTS ipb_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS ipb_emails CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'u_system'@'%' IDENTIFIED BY 'Ipb@Syst3m';
CREATE USER IF NOT EXISTS 'u_emails'@'%' IDENTIFIED BY 'Ipb@Emai1s';
GRANT ALL PRIVILEGES ON ipb_system.* TO 'u_system'@'%';
GRANT ALL PRIVILEGES ON ipb_emails.* TO 'u_emails'@'%';
FLUSH PRIVILEGES;
"
```

(Use your actual `MYSQL_ROOT_PASSWORD` from the repo root `.env` if it’s not `root`.)

---

## Step 5: Install PHP dependencies (Composer)

From **`laravel-docker-env`**:

```bash
docker compose exec php bash -c "cd /var/www/paynbill && composer install"
```

Or: `./scripts/composer.sh paynbill install`

---

## Step 6: Run migrations

```bash
docker compose exec php bash -c "cd /var/www/paynbill && php artisan migrate"
```

Or: `make art p=paynbill c="migrate"` (if using Make) or `./scripts/artisan.sh paynbill migrate`

If you need a fresh DB: `make art p=paynbill c="migrate:fresh --seed"` (or equivalent).

---

## Step 7: Fix storage and upload permissions

If you see permission errors (storage, cache, or **file uploads** such as signature image in General Settings):

```bash
make permissions-paynbill
```

This sets `www-data` as owner of `storage`, `bootstrap/cache`, and **`public`** so the app can create upload dirs (e.g. `public/<client>timesheets/signature/`). If you only need storage/cache:

```bash
make permissions
```

Or manually:

```bash
docker compose exec php chown -R www-data:www-data /var/www/paynbill/storage /var/www/paynbill/bootstrap/cache /var/www/paynbill/public
```

---

## Step 8: Open the app

In the browser:

- **http://paynbill.local**  
- or **http://dev.paynbill.local**

(Use the same host as in `APP_URL` in `.env`.)

---

## Optional: Queue worker (if the app uses queues)

To run the paynbill queue worker via Supervisor, add this to **`docker/supervisor/supervisord.conf`** (then restart PHP):

```ini
[program:paynbill-worker]
command=php /var/www/paynbill/artisan queue:work --sleep=3 --tries=3
directory=/var/www/paynbill
autostart=true
autorestart=true
user=www-data
stdout_logfile=/var/log/supervisor/paynbill-worker.log
stderr_logfile=/var/log/supervisor/paynbill-worker.err.log
```

Then: `docker compose restart php`

---

## Troubleshooting

### "Failed to open stream: No such file or directory" when uploading (e.g. signature image)

- The app needs to create directories under `public/` (e.g. `public/testtimesheets/signature/`). After moving the project (e.g. rsync from Windows to WSL), the PHP process may not be able to create them.
- **Fix:** Run `make permissions-paynbill` so `www-data` owns `public/`. Then retry the upload.
- Ensure the system client has a valid **timesheet path** in Settings (e.g. `testtimesheets` for client alias `test`).

---

## DB schema migration (client-level SQL)

To run the production-style schema migration (e.g. `IPB-1449-client-schema.sql`) against all client databases:

```bash
make migratedbschema-paynbill
```

Or:

```bash
docker compose exec php bash -c "cd /var/www/paynbill && php artisan migratedbschema:update"
```

You will be prompted for the SQL file name(s). The PHP container has `mariadb-client` installed and connects to MariaDB via a **shared socket** (no `-h` needed); the socket is mounted from the MariaDB container so the same command works as on production.

---

## Quick reference

| Task              | Command |
|-------------------|--------|
| Artisan           | `./scripts/artisan.sh paynbill migrate` or `make art p=paynbill c="migrate"` |
| Composer          | `./scripts/composer.sh paynbill install` |
| DB schema migration (client SQL) | `make migratedbschema-paynbill` |
| Permissions (storage + public for uploads) | `make permissions-paynbill` |
| Shell (project dir)| `docker compose exec php bash -c "cd /var/www/paynbill && exec bash"` |
| Logs              | `docker compose logs -f php nginx` |
