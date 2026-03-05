# Credit Control API – Docker setup (Windows 11 + WSL2)

Node.js 24, PM2, MongoDB 8, Redis (shared), Nginx upstream to port 8085.

---

## 1. Repo root `.env`

Copy from `.env.example` and set:

```env
REDIS_PASSWORD=your_strong_redis_password
MONGO_ROOT_PASSWORD=root
```

Use the same `REDIS_PASSWORD` in the Credit Control app (see below).

---

## 2. Credit Control app `.env`

In **`projects/credit-control/.env`** (copy from `.env.example`), set:

- **Redis** (must match repo root `REDIS_PASSWORD`):
  ```env
  REDIS_URL=redis://:your_strong_redis_password@redis:6379
  ```

- **MongoDB** (user created by `docker/mongodb/init/01-create-cc-admin.js`):
  ```env
  MONGO_DB_BASE_URI=mongodb://ccDevAdm:it!sVinExp1!8ccAdm@mongodb:27017/
  MONGO_DB_PREFIX=cc_
  ```

- **Port** (already 8085):
  ```env
  APP_PORT=8085
  ```

---

## 3. Start stack

From repo root:

```bash
docker compose up -d
```

This starts:

- **credit-control**: NVM + Node 24, installs deps, `npm run build:dev`, then `pm2 start ecosystem.config.cjs --env local --no-daemon` (API on 8085).
- **credit-control-frontend**: NVM + Node 24, `npm run dev` (Vite on 5173). Nginx proxies `dev-cc.integra-paybill2.co.uk` → 5173.
- **mongodb**: MongoDB 8 with auth; root from `MONGO_ROOT_PASSWORD`, admin user `ccDevAdm` from init script.
- **redis**: Password from `REDIS_PASSWORD`; AOF and dangerous commands disabled.
- **nginx**: Proxies to API (8085) and frontend (5173).

---

## 4. Credit Control React frontend (Vite)

The frontend runs in its own container (`credit-control-frontend`) with `npm run dev` (Vite on port 5173). Nginx proxies **dev-cc.integra-paybill2.co.uk** to it.

Add to hosts (alongside the API host):

- **Windows** (`C:\Windows\System32\drivers\etc\hosts`) / **WSL2** (`/etc/hosts`):
  ```
  127.0.0.1 dev-cc-api.integra-paybill2.co.uk
  127.0.0.1 dev-cc.integra-paybill2.co.uk
  127.0.0.1 credit-control.local
  ```

Then open:

- **Frontend**: http://dev-cc.integra-paybill2.co.uk  
- **API**: http://dev-cc-api.integra-paybill2.co.uk  

API URL for the frontend is set via `VITE_API_BASE_URL` in docker-compose (default `http://dev-cc-api.integra-paybill2.co.uk/api/v1/`).

---

## 5. Useful commands

| Task              | Command |
|-------------------|--------|
| Build Node image  | `make cc-build` or `docker compose build credit-control` |
| API logs (stdout) | `make cc-logs` or `docker compose logs -f credit-control` |
| API file logs     | `storage/logs/credit-control/YYYY-MM-DD.log` (from repo root) |
| Shell in container| `make cc-shell` |
| PM2 status        | `make cc-pm2-status` |
| PM2 restart       | `make cc-pm2-restart` |
| Create ccDevAdm user | `make cc-mongo-create-user` (when "Authentication failed") |
| Restore databases | `make cc-mongo-restore` (put mongodump in `storage/mongodb-restore/`) |
| Reset MongoDB data| `make cc-mongo-reset` (see Troubleshooting) |
| Fix log file permissions | `make fix-storage-permissions` (edit/delete files in storage/logs) |
| MongoDB Compass (from host) | Port **27018** (avoids conflict with local Windows MongoDB on 27017) |

---

## 6. Redis and MongoDB – how they connect

### Redis

| Where | Value | Purpose |
|-------|-------|---------|
| **Repo root `.env`** | `REDIS_PASSWORD=root` | Used by Redis container and docker-compose for `REDIS_URL` |
| **Redis container** | Runs with `--requirepass $REDIS_PASSWORD` | Enforces auth |
| **credit-control** | `REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379` | Injected into container; `:root` = password before `@` |

Flow: Repo `.env` → `REDIS_PASSWORD` → Redis `requirepass` + `REDIS_URL` in credit-control. Same password everywhere.

### MongoDB

| Where | Value | Purpose |
|-------|-------|---------|
| **docker/mongodb/init/** | Creates `ccDevAdm` with password `it!sVinExp1!8ccAdm` | One-time init when data dir is empty |
| **docker-compose** | `MONGO_DB_BASE_URI=...@mongodb:27017/` | Injected into credit-control; host must be `mongodb` |

Inside Docker, MongoDB host is `mongodb`, not `localhost`. Docker-compose env vars override project `.env` files.

**Store-specific DBs:** Each store has its own MongoDB DB with credentials in User Management (UM). UM stores `localhost` for local dev. When credit-control runs in Docker, `MONGO_STORE_HOST_OVERRIDE=mongodb` redirects those connections to the MongoDB container.

**MongoDB Compass (from host):** Use port **27018** (Docker maps 27018→27017 so local Windows MongoDB on 27017 is unaffected). Connection string:
```
mongodb://root:it!sVinExp1!8ccAdm@localhost:27018/?authSource=admin
```
Or use `ccDevAdm` with the same password. Keep both connections in Compass: localhost:27017 (Windows) and localhost:27018 (Docker).

---

## 7. Troubleshooting: "Authentication failed" (MongoDB, not Redis)

If you see:
```
[INFO] Redis Client Connected: redis://:root@redis:6379
[ERROR] Failed to initialize server: Authentication failed.
```
Redis is fine. The error is from **MongoDB**.

Fix: When running via `make cc-shell`, use `mongodb` as host in `.env.local`:
```env
MONGO_DB_BASE_URI=mongodb://ccDevAdm:it!sVinExp1!8ccAdm@mongodb:27017/?authSource=admin

**Root cause:** The `ccDevAdm` user does not exist. The init script (`docker/mongodb/init/01-create-cc-admin.js`) runs **only when the MongoDB data directory is empty** on first start. If MongoDB was already initialised before this script was added, `ccDevAdm` was never created.

**Fix – create the user:**
```bash
make cc-mongo-create-user
```

Then restart: `docker compose restart credit-control` or run `npm run dev` again in `make cc-shell`.

**Alternative:** Full reset (wipes all MongoDB data):
```bash
make cc-mongo-reset
docker compose up -d credit-control
```

---

## 8. Troubleshooting: “dependency mongodb failed to start” / SCRAM storedKey mismatch

If **credit-control** fails with “Error dependency mongodb failed to start”, check MongoDB logs:

```bash
docker compose logs mongodb
```

If you see **`SCRAM authentication failed, storedKey mismatch`** for user `root`, the MongoDB data in `./storage/mongodb` was created with a **different** `MONGO_ROOT_PASSWORD` than in your current repo `.env`. The healthcheck uses the root user and current `.env` password, so it keeps failing and Docker never marks mongodb as healthy. (The healthcheck is configured to support passwords with special characters like `!`.)

**Fix:** Reset MongoDB so it re-initializes with your current `MONGO_ROOT_PASSWORD`:

```bash
make cc-mongo-reset
```

This stops mongodb, wipes `storage/mongodb` (using a one-off container so you don’t need sudo), and starts mongodb again. On first start it will create the root user and run the init script (ccDevAdm). **All existing MongoDB data will be lost.** After mongodb is healthy, start the rest of the stack:

```bash
docker compose up -d credit-control
```

If you prefer to keep existing data, set `MONGO_ROOT_PASSWORD` in `.env` to whatever password was used when that data was first created.

---

## 9. NVM and multiple Node versions

The Node container uses **NVM** so you can install and switch between Node 24, 20, 18, etc. for different projects.

- **Default**: Node 24 (used by Credit Control and by the container’s default CMD).
- **Inside the container** (e.g. `make cc-shell` or `docker compose exec credit-control bash`):

  ```bash
  . $NVM_DIR/nvm.sh   # load NVM (or open a new bash session so .bashrc loads it)

  nvm list            # installed versions
  nvm install 20      # install Node 20 LTS
  nvm install 18      # install Node 18 LTS
  nvm use 20          # use Node 20 for this shell
  nvm use 24          # switch back to 24
  nvm alias default 24   # optional: change default for new shells
  ```

- **Running another Node project** (e.g. Node 20):
  - Either add a second service in `docker-compose.yml` that uses the same `docker/node` image and a different CMD (e.g. `nvm use 20 && cd /var/www/other-project && pm2 start ...`).
  - Or use one container and one PM2 ecosystem: start Credit Control with Node 24 and the other app with Node 20 by switching in the start script or by running PM2 under the right `nvm use` (e.g. a small wrapper script that runs `nvm use 20 && pm2 start other-ecosystem.config.cjs`). You can also add more apps to `projects/credit-control/ecosystem.config.cjs` and run them with different Node versions by starting them from a script that sets `nvm use <version>` before each `pm2 start`.

---

## 10. Stack summary

| Component        | Image / build     | Notes |
|------------------|-------------------|--------|
| Node.js          | docker/node (Debian + NVM) | NVM installs Node 24 by default; add 18/20 with `nvm install`. PM2 global. |
| MongoDB          | mongo:8           | Auth via `mongod --auth`. Init creates `ccDevAdm`. |
| Redis            | redis:8.0-alpine  | `requirepass` from `REDIS_PASSWORD`; AOF; FLUSHALL/FLUSHDB/CONFIG disabled. |
| Nginx            | nginx:1.26-alpine | Upstream `credit_control_api` → `credit-control:8085`. |
