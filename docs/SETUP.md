# Complete Setup Guide - Docker Laravel Environment

This guide walks through setting up the Docker-based Laravel/Node.js development environment on Windows 11 with WSL2.

**Estimated time:** 30–45 minutes (first-time setup)

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Install WSL2](#step-1-install-wsl2)
3. [Step 2: Install Docker Desktop](#step-2-install-docker-desktop)
4. [Step 3: Clone This Repository](#step-3-clone-this-repository)
5. [Step 4: Configure Environment](#step-4-configure-environment)
6. [Step 5: Start Docker Containers](#step-5-start-docker-containers)
7. [Step 6: Add Your First Laravel Project](#step-6-add-your-first-laravel-project)
8. [Step 7: Verify Installation](#step-7-verify-installation)
9. [Next Steps](#next-steps)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Windows 11 (Pro, Enterprise, or Education)
- At least 8GB RAM (16GB recommended)
- At least 20GB free disk space
- Administrator access
- Stable internet connection

---

## Step 1: Install WSL2

### 1.1 Check if WSL2 is Installed

Open **PowerShell** as Administrator:

```powershell
wsl --version
```

If you see version information, WSL2 is installed. Skip to Step 2.

### 1.2 Install WSL2

```powershell
wsl --install
```

Or specify Ubuntu: `wsl --install -d Ubuntu-24.04`

### 1.3 Restart Your Computer

Restart when prompted.

### 1.4 Set Up Ubuntu

Create a username and password when Ubuntu opens.

### 1.5 Update Ubuntu

```bash
sudo apt update && sudo apt upgrade -y
```

### 1.6 Verify

```bash
wsl --version
lsb_release -a
```

---

## Step 2: Install Docker Desktop

### 2.1 Download Docker Desktop

From https://www.docker.com/products/docker-desktop

### 2.2 Install

1. Run the installer
2. Check **Use WSL 2 instead of Hyper-V**
3. Restart when prompted

### 2.3 Configure Docker Desktop

1. Open Docker Desktop
2. **Settings** → **General** → Use the WSL 2 based engine
3. **Resources** → **WSL Integration** → Enable your Ubuntu distro
4. Apply & Restart

### 2.4 Resource Limits (Optional)

Create or edit `C:\Users\YourUsername\.wslconfig`:

```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
localhostForwarding=true
```

Restart WSL: in PowerShell as Administrator: `wsl --shutdown`, then open Ubuntu again.

### 2.5 Verify Docker in WSL2

```bash
docker --version
docker compose version
docker run hello-world
```

---

## Step 3: Clone This Repository

### 3.1 Work in WSL2

Store the repo in the WSL filesystem for best performance:

```bash
cd ~
git clone <YOUR_REPOSITORY_URL> laravel-docker-env
cd laravel-docker-env
```

### 3.2 Expected Layout

- `docker/` – Nginx, PHP, MariaDB, Redis, MongoDB configs
- `projects/` – Laravel/Node projects
- `scripts/` – Helper scripts
- `storage/` – Data and logs (gitignored)
- `docker-compose.yml`, `Makefile`, `.env.example`

---

## Step 4: Configure Environment

### 4.1 Run First-Time Setup Script

```bash
chmod +x scripts/first-time-setup.sh
./scripts/first-time-setup.sh
```

This script will:

- Check prerequisites (Docker, WSL2)
- Create required directories
- Copy `.env.example` to `.env`
- Prompt for passwords
- Set script and storage permissions

### 4.2 Manual Alternative

```bash
cp .env.example .env
nano .env
```

Update at least:

```env
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_PASSWORD=your_secure_laravel_password
REDIS_PASSWORD=your_redis_password
MONGO_ROOT_PASSWORD=your_mongo_password
```

### 4.3 Script Permissions

```bash
chmod +x scripts/*.sh
```

---

## Step 5: Start Docker Containers

### 5.1 Build and Start

```bash
make up
# or: docker compose up -d --build
```

First run may take 5–10 minutes.

### 5.2 Check Status

```bash
make ps
```

Expect services such as:

- `laravel-nginx`
- `laravel-php`
- `laravel-mariadb`
- `laravel-redis`
- `laravel-mongodb`
- `laravel-credit-control`
- `laravel-credit-control-frontend`

### 5.3 View Logs

```bash
make logs
# or: make logs s=nginx
```

---

## Step 6: Add Your First Laravel Project

### Option A: New Project via Script

```bash
make new-project
```

You will be prompted for project name and database name.

### Option B: Clone Existing Project

```bash
cd projects
git clone https://github.com/your-org/your-project.git myapp
cd ..
```

### Option C: Create New Laravel with Composer

```bash
docker compose exec php bash -c "cd /var/www && composer create-project laravel/laravel myapp"
```

### 6.1 Laravel `.env` (Docker)

Use service names as hosts. Copy from `templates/laravel-env-template` and adjust:

```env
DB_HOST=mariadb
DB_DATABASE=myapp_db
DB_USERNAME=laravel
DB_PASSWORD=<same as MYSQL_PASSWORD in root .env>

REDIS_HOST=redis
REDIS_PASSWORD=<same as REDIS_PASSWORD in root .env>
```

### 6.2 Create Database (if not auto-created)

```bash
make db-create
# Enter database name when prompted (e.g. myapp_db)
```

### 6.3 Install Dependencies & Migrate

```bash
make composer p=myapp c="install"
make art p=myapp c="key:generate"
make art p=myapp c="migrate"
```

### 6.4 Nginx Virtual Host

If you used `make new-project`, the Nginx vhost is already created.

Otherwise, copy the template:

```bash
cp docker/nginx/sites/_template.conf docker/nginx/sites/myapp.conf
# Replace PROJECTNAME with myapp in the file
```

### 6.5 Windows Hosts File

On Windows (as Administrator), edit `C:\Windows\System32\drivers\etc\hosts`:

```
127.0.0.1 myapp.local
```

### 6.6 Restart Containers

```bash
make restart
```

---

## Step 7: Verify Installation

### 7.1 Web Access

Open http://myapp.local in your browser.

### 7.2 Database

```bash
make mysql
SHOW DATABASES;
exit
```

### 7.3 Redis

```bash
docker compose exec redis redis-cli -a "$REDIS_PASSWORD" PING
# Expect: PONG
```

### 7.4 Artisan

```bash
make art p=myapp c="route:list"
```

---

## Next Steps

- Add more projects with `make new-project`
- Enable Xdebug in `.env` when debugging
- Check [README.md](../README.md) for common commands
- See [docs/PERFORMANCE.md](PERFORMANCE.md) for performance tips

---

## Troubleshooting

### Docker Desktop Won't Start

- Confirm WSL 2 is in use
- Restart the computer
- Check that the Docker Desktop Service is running

### "Cannot connect to database"

```bash
make ps
make logs s=mariadb
make mysql
# Verify DB exists
make restart
```

### Permission Denied in Laravel

```bash
make permissions p=myapp
```

### 502 Bad Gateway

```bash
make logs s=php
docker compose restart php
docker compose exec nginx nginx -t
```

### Slow Performance

1. Ensure the repo is in the WSL filesystem (not `\mnt\c\`)
2. Increase WSL/Docker resources (see Step 2.4)
3. Disable Xdebug when not debugging: `XDEBUG_MODE=off` in `.env`

### MongoDB Restore

Place mongodump output in `storage/mongodb-restore/` and run:

```bash
make cc-mongo-restore
```

See `storage/mongodb-restore/README.md` for details.

---

## Getting Help

- View logs: `make logs` or `make logs s=<service>`
- Shell into PHP: `make shell p=myapp`
- Container status: `make ps`
- Open an issue on the repository
