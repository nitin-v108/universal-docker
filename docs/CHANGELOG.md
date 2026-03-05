# Changelog

Notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Changed

- **MongoDB Credit Control credentials**: Replaced hardcoded `ccDevAdm` password in docker-compose with env vars. Add to `.env`:
  ```
  MONGO_CC_ADMIN_USER=ccDevAdm
  MONGO_CC_ADMIN_PASSWORD=<your-secure-password>
  ```
  If you had existing MongoDB data with the old password, set `MONGO_CC_ADMIN_PASSWORD` to match.

### Added

- Comprehensive documentation (SETUP, CONTRIBUTING, GIT_SETUP)
- First-time setup script (`scripts/first-time-setup.sh`)
- create-gitkeep script (`scripts/create-gitkeep.sh`)
- Laravel .env template (`templates/laravel-env-template`)
- .gitattributes for line endings
- .gitignore for boilerplate Git hygiene

---

## [1.0.0] - 2026-02-XX

### Added

- Docker environment for multiple Laravel/Node.js projects
- WSL2-optimized configuration for Windows 11
- Services: Nginx 1.26, PHP 8.3-FPM, PHP 5.6 (legacy), MariaDB 10.11, Redis 8.0, MongoDB 8, Node.js (Credit Control)
- Makefile with common commands
- Automated project setup script
- Xdebug configuration
- Supervisor for queue workers
- Credit Control API (Node.js + PM2 + MongoDB)
- Credit Control Frontend (Vite)
- Multiple Nginx vhosts support

### Features

- Shared infrastructure across projects
- Hot reload / file watching
- Persistent MariaDB, MongoDB, and Redis storage
- Easy project management via Makefile
- MongoDB restore workflow (see storage/mongodb-restore/README.md)

---

## Version History Notes

- **Added** – new features
- **Changed** – changes in existing functionality
- **Deprecated** – features to be removed
- **Removed** – removed features
- **Fixed** – bug fixes
- **Security** – vulnerability-related changes

When making changes:

1. Add an entry under [Unreleased]
2. Commit with a clear message
3. Tag releases: `git tag v1.1.0` then `git push origin v1.1.0`
