# Projects Directory

This directory contains your Laravel and Node.js applications. Each project has its own Git repository and is **not** version-controlled by this boilerplate.

## Adding a Project

### Option 1: Using the script (recommended)

```bash
make new-project
```

You will be prompted for project name and database name.

### Option 2: Clone an existing project

```bash
cd projects
git clone https://github.com/your-org/your-project.git myapp
```

### Option 3: Create a new Laravel project

```bash
docker compose exec php bash -c "cd /var/www && composer create-project laravel/laravel myapp"
```

## Configuration

- Place your project in `projects/<name>/`
- Configure Laravel `.env` with `DB_HOST=mariadb`, `REDIS_HOST=redis`
- Add host entry: `127.0.0.1 myapp.local` in `C:\Windows\System32\drivers\etc\hosts`
- See `templates/laravel-env-template` for Docker-specific `.env` values

## Directory Layout

```
projects/
├── myapp/          # Laravel project (own Git repo)
├── paynbill/       # Another Laravel project
├── credit-control/ # Node.js/Express project
└── ...
```
