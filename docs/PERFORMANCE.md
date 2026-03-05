# Local development performance guide

Laravel in Docker on **Windows** is often slow because of **bind-mounted volumes**: every file read (PHP, config, views, vendor) goes through the host filesystem. This guide reduces that impact and speeds up the stack.

---

## 1. Use Redis for cache and session (done for paynbill)

**Already applied** in `projects/paynbill/.env`:

- `CACHE_DRIVER=redis`
- `SESSION_DRIVER=redis`

This moves cache and session off the filesystem into Redis (in-memory), which is much faster and reduces disk I/O on the project volume. No code changes needed.

If you add another project, set the same in that project's `.env`.

---

## 2. OPcache revalidate interval

In **`docker/php/php.ini`**:

- `opcache.revalidate_freq = 1` — PHP rechecks file changes every **1 second** instead of every request. This cuts a lot of `stat()` calls and speeds up responses. Code changes still show up within about a second.
- If you want changes to show **immediately**, set `opcache.revalidate_freq = 0` (slower).

Restart PHP after editing: `docker compose restart php`.

---

## 3. Laravel config and view cache (optional, big win)

Caching config and views avoids loading/compiling them on every request. Use only when you're not changing config or Blade files often.

**Enable (faster):**

```bash
docker compose exec php bash -c "cd /var/www/paynbill && php artisan config:cache && php artisan view:cache"
```

**Disable when you change `.env` or Blade templates:**

```bash
docker compose exec php bash -c "cd /var/www/paynbill && php artisan config:clear && php artisan view:clear"
```

Tip: use cache during normal coding; clear when you change `.env` or add new config keys.

---

## 4. Optimized Composer autoloader

Reduces autoload overhead on each request:

```bash
docker compose exec php bash -c "cd /var/www/paynbill && composer dump-autoload -o"
```

Run again after `composer require` or `composer update`.

---

## 5. Keep Xdebug off unless you need it

Xdebug can make requests 2–10x slower. In the **repo root** `.env`:

- `XDEBUG_MODE=off` (default)

Only set `XDEBUG_MODE=debug` when you're actively debugging, then set it back to `off`.

---

## 6. Windows: use WSL2 and put the project in WSL (largest gain)

When the project lives on a **Windows path** (e.g. `D:\Projects\Integra\...`) and is bind-mounted into Docker, file I/O is very slow.

**Best approach:** move the project into **WSL2** and run Docker from there. You keep using Windows as your main OS; only the project files and Docker run from WSL.

---

### WSL2 migration – what to do

**Prerequisites:** WSL2 installed (e.g. Ubuntu). Docker Desktop with **WSL2** engine enabled (Settings → General → "Use the WSL 2 based engine").

**1. Stop containers (from Windows)**

In PowerShell or CMD, from your current project root:

```powershell
cd D:\Projects\Integra\laravel-docker-env
docker compose down
```

**2. Open WSL and pick a target directory**

Open **Ubuntu** (or your WSL distro) from the Start menu or run `wsl` in a terminal. Then:

```bash
# Create a projects folder in your WSL home (optional but tidy)
mkdir -p ~/projects
cd ~/projects
```

**3. Copy the project from the Windows drive into WSL**

Your `D:` drive is available in WSL as `/mnt/d/`. You **must exclude** `storage/redis`, `storage/mysql`, and `storage/logs` — Docker and PHP-FPM create files there with permissions that cause "Permission denied" when copying from `/mnt/d/`. Containers will create fresh data/logs in WSL when you start them.

**Option A – Recommended (faster, skips heavy/dangerous dirs):**

```bash
rsync -a --progress \
  --exclude 'projects/*/node_modules' \
  --exclude 'projects/*/vendor' \
  --exclude 'storage/mysql' \
  --exclude 'storage/redis' \
  --exclude 'storage/logs' \
  --exclude '.git' \
  /mnt/d/Projects/Integra/laravel-docker-env/ \
  ~/projects/laravel-docker-env/
```

**Option B – Full copy including `.git` (still exclude storage to avoid permission errors):**

```bash
rsync -a --progress \
  --exclude 'storage/mysql' \
  --exclude 'storage/redis' \
  --exclude 'storage/logs' \
  /mnt/d/Projects/Integra/laravel-docker-env/ \
  ~/projects/laravel-docker-env/
```

If `rsync` is not installed: `sudo apt update && sudo apt install -y rsync`.

Do **not** use `cp -a` on the whole folder — `storage/redis`, `storage/mysql`, and `storage/logs` are written by containers and often cause "Permission denied" when copied from the Windows mount. Use one of the `rsync` commands above.

**4. Restore dependencies inside WSL (if you excluded vendor/node_modules)**

```bash
cd ~/projects/laravel-docker-env
docker compose up -d
# After containers are up, install PHP/JS deps for paynbill:
docker compose exec php bash -c "cd /var/www/paynbill && composer install"
# If the project uses Node: docker compose exec php bash -c "cd /var/www/paynbill && npm ci"
```

**5. Open the project in Cursor from WSL**

- Install the **WSL** extension in Cursor if you haven't (e.g. "WSL" by Microsoft).
- Press `F1` or `Ctrl+Shift+P` → run **"WSL: Connect to WSL"** (or from the bottom-left green icon choose "Connect to WSL").
- Then **File → Open Folder** and choose:
  - `\\wsl$\Ubuntu\home\<your-username>\projects\laravel-docker-env`  
  or type in the path bar: `\\wsl$\Ubuntu\home\<your-username>\projects\laravel-docker-env`  
  (Replace `Ubuntu` with your distro name if different, and `<your-username>` with your WSL username.)
- You're now editing files **inside WSL**. Docker Compose will use the Linux filesystem and performance will be much better.

**6. Use the app as before**

- **URLs:** Same as before — e.g. http://paynbill.local (your Windows hosts file still points `127.0.0.1` to these; Docker Desktop exposes ports to localhost).
- **Run commands** from the integrated terminal in Cursor (it will be a WSL shell in that folder), e.g.:
  - `docker compose up -d`
  - `docker compose exec php bash -c "cd /var/www/paynbill && php artisan migrate"`
- If **file uploads** (e.g. signature image) fail with "No such file or directory", run `make permissions-paynbill` so the app can create dirs under `public/`. See [SETUP-PAYNBILL.md](SETUP-PAYNBILL.md).

**7. Optional: exclude WSL from Windows Defender**

For extra speed, add an exclusion so Defender doesn't scan the WSL filesystem used by the project:

- **Windows Security** → **Virus & threat protection** → **Exclusions** → add:
  - `\\wsl$\Ubuntu\home\<your-username>\projects`  
  (or your actual WSL project path).

---

### One-time setup summary

| Step | Where | Action |
|------|--------|--------|
| 1 | Windows (PowerShell) | `cd D:\Projects\Integra\laravel-docker-env` → `docker compose down` |
| 2 | WSL | `mkdir -p ~/projects && cd ~/projects` |
| 3 | WSL | `rsync ...` or `cp -a ...` from `/mnt/d/Projects/Integra/laravel-docker-env` to `~/projects/laravel-docker-env` |
| 4 | WSL | `cd ~/projects/laravel-docker-env` → `docker compose up -d` → run `composer install` (and `npm ci` if needed) in container |
| 5 | Cursor | WSL: Connect to WSL → Open Folder → `\\wsl$\Ubuntu\home\<you>\projects\laravel-docker-env` |
| 6 | Browser | Open http://paynbill.local as before |

After this, do all development from the **WSL folder** in Cursor. You can keep the old `D:\Projects\Integra\laravel-docker-env` as a backup or remove it once you're happy.

---

## 7. Windows Defender: exclude project and Docker paths

Real-time scanning on the project and Docker data can add a lot of latency. Add exclusions (as Administrator):

1. **Windows Security** → **Virus & threat protection** → **Manage settings** → **Exclusions** → **Add or remove exclusions**.
2. Add folder exclusions for:
   - Your project root, e.g. `D:\Projects\Integra\laravel-docker-env`
   - Docker data (e.g. `%LOCALAPPDATA%\Docker\wsl` or the path shown in Docker Desktop → Settings → Resources → File sharing).

Restart Docker Desktop after adding exclusions if things still feel slow.

---

## 8. Docker Desktop resources

Give Docker enough CPU and RAM:

- **Docker Desktop** → **Settings** → **Resources**:
  - **CPUs:** at least 4 (if you have them).
  - **Memory:** at least 4 GB, 6–8 GB if possible.
  - **Swap:** 1–2 GB.

Apply & Restart.

---

## 9. Optional: disable Debug Bar / Telescope in local

If the app uses **Laravel Debugbar** or **Telescope**, they add overhead on every request. To speed up:

- **Debugbar:** in `.env` set `DEBUGBAR_ENABLED=false` (if the package supports it), or disable in the package config for local.
- **Telescope:** in `config/telescope.php` you can limit recording to specific environments or disable when not debugging.

---

## 10. Summary checklist

| Action | Effect |
|--------|--------|
| Redis for cache + session | High – less filesystem I/O |
| `opcache.revalidate_freq = 1` | High – fewer file stats |
| `config:cache` + `view:cache` | High – fewer file reads (clear when changing config/views) |
| `composer dump-autoload -o` | Medium – faster autoload |
| Xdebug off | High when not debugging |
| Project in WSL2 | Very high on Windows |
| Defender exclusions | High on Windows |
| More Docker CPU/RAM | Medium |

After changing PHP or Nginx config, restart:

```bash
docker compose restart php nginx
```

After changing Laravel `.env` or config, clear caches if you had cached config/views:

```bash
docker compose exec php bash -c "cd /var/www/paynbill && php artisan config:clear && php artisan cache:clear"
```
