#!/bin/sh
# Create ccDevAdm user in MongoDB if missing (init script runs only when data dir is empty)
# Use when: "Authentication failed" but Redis connects; ccDevAdm was never created
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Load MONGO_ROOT_PASSWORD from .env (for root auth)
if [ -f .env ]; then
  MONGO_ROOT_PASSWORD=$(grep '^MONGO_ROOT_PASSWORD=' .env 2>/dev/null | sed 's/^MONGO_ROOT_PASSWORD=//' | tr -d '\r')
fi
MONGO_ROOT_PASSWORD="${MONGO_ROOT_PASSWORD:-root}"

# ccDevAdm uses MONGO_CC_ADMIN_* from container env (set by docker-compose from .env)
# This avoids shell-escaping issues with special chars in passwords
docker compose exec mongodb mongosh --username root --password "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin --eval '
  const user = process.env.MONGO_CC_ADMIN_USER || "ccDevAdm";
  const pwd = process.env.MONGO_CC_ADMIN_PASSWORD;
  if (!pwd) throw new Error("MONGO_CC_ADMIN_PASSWORD must be set in .env");
  const adminDb = db.getSiblingDB("admin");
  const users = adminDb.getUsers().users || [];
  const ccUser = users.find(u => u.user === user);
  const roles = [
    { role: "userAdminAnyDatabase", db: "admin" },
    { role: "readWriteAnyDatabase", db: "admin" },
    { role: "dbAdminAnyDatabase", db: "admin" }
  ];
  if (!ccUser) {
    adminDb.createUser({ user, pwd, roles });
    print(user + " created");
  } else {
    const hasDbAdmin = ccUser.roles.some(r => r.role === "dbAdminAnyDatabase");
    if (!hasDbAdmin) {
      adminDb.grantRolesToUser(user, [{ role: "dbAdminAnyDatabase", db: "admin" }]);
      print(user + " updated: granted dbAdminAnyDatabase");
    } else {
      print(user + " already has required roles");
    }
  }
'
