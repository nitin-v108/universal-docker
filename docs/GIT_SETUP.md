# Git Setup Instructions

How to set up Git for this boilerplate and manage updates.

---

## Initial Repository Setup

### 1. Initialize Git

```bash
cd laravel-docker-env
git init
git add .
git commit -m "Initial commit: Docker Laravel boilerplate v1.0.0"
```

### 2. Create Remote Repository

1. Create a new repository (e.g. GitHub, GitLab, Bitbucket)
2. Do not initialize with a README if the project already has one

### 3. Connect and Push

```bash
git remote add origin https://github.com/yourusername/laravel-docker-env.git
git branch -M main
git push -u origin main

git tag v1.0.0
git push origin v1.0.0
```

---

## What .gitignore Excludes

### Never Committed

- **Secrets:** `.env` (passwords, keys)
- **Database data:** `storage/mysql/*`, `storage/mongodb/*`, `storage/redis/*`
- **Logs:** `storage/logs/**/*`
- **MongoDB restore dumps:** `storage/mongodb-restore/dump/` (README.md is kept)
- **Projects:** `projects/*` (each project has its own repo)

### Always Committed

- Docker config: `docker-compose.yml`, `docker/`
- Scripts: `scripts/`
- Docs: `docs/`, `README.md`, `storage/mongodb-restore/README.md`
- Templates: `templates/`, `.env.example`
- Directory structure: `.gitkeep` files

---

## Managing Laravel Projects

### Separate Repositories

```bash
cd projects/myapp
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourusername/myapp.git
git push -u origin main
```

The boilerplate repo and each project repo are independent.

---

## Updating the Boilerplate

### Workflow

1. Make changes to Docker config and scripts
2. Test: `make rebuild && make ps`
3. Update `docs/CHANGELOG.md`
4. Commit and push:
   ```bash
   git add .
   git commit -m "Update: description of changes"
   git push origin main
   ```
5. Tag releases when appropriate:
   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```

---

## Pulling Updates on Another Machine

```bash
cd laravel-docker-env
git pull origin main
make rebuild
make up
```

---

## Best Practices

1. Commit often with small, logical changes
2. Write clear commit messages with prefixes (Add, Fix, Update, Docs)
3. Test with `make rebuild` before committing
4. Document changes in `docs/CHANGELOG.md`
5. Tag releases (e.g. v1.0.0, v1.1.0)
6. Do not commit `.env` or secrets
7. Keep projects in separate Git repositories
