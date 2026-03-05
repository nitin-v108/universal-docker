#!/bin/sh
# Restore 2 (or more) databases from mongodump export into Docker MongoDB
# Usage: Place your dump in storage/mongodb-restore/ then run: make cc-mongo-restore
#
# Expected structure in storage/mongodb-restore/:
#   Option A (standard mongodump):  dump/dbname1/  dump/dbname2/
#   Option B (flattened):           dbname1/  dbname2/
#
# Each db folder contains: collection.bson, collection.metadata.json
# Export from source: mongodump --uri="mongodb://..." --out=./mybackup
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESTORE_DIR="$REPO_ROOT/storage/mongodb-restore"
cd "$REPO_ROOT"

# Load Credit Control admin credentials from .env
if [ -f .env ]; then
  MONGO_CC_ADMIN_USER=$(grep '^MONGO_CC_ADMIN_USER=' .env 2>/dev/null | sed 's/^MONGO_CC_ADMIN_USER=//' | tr -d '\r')
  MONGO_CC_ADMIN_PASSWORD=$(grep '^MONGO_CC_ADMIN_PASSWORD=' .env 2>/dev/null | sed 's/^MONGO_CC_ADMIN_PASSWORD=//' | tr -d '\r')
fi
MONGO_CC_ADMIN_USER="${MONGO_CC_ADMIN_USER:-ccDevAdm}"
MONGO_CC_ADMIN_PASSWORD="${MONGO_CC_ADMIN_PASSWORD:?MONGO_CC_ADMIN_PASSWORD must be set in .env}"

if [ ! -d "$RESTORE_DIR" ]; then
  echo "Error: $RESTORE_DIR does not exist. Create it and place your mongodump output there."
  exit 1
fi

# Use dump/ if present (standard mongodump output), else use restore dir directly
if [ -d "$RESTORE_DIR/dump" ]; then
  DUMP_PATH="/restore/dump"
else
  DUMP_PATH="/restore"
fi

# Ensure there are db folders to restore
if ! ls "$RESTORE_DIR"/*/ 1>/dev/null 2>&1 && ! ls "$RESTORE_DIR"/dump/*/ 1>/dev/null 2>&1; then
  echo "Error: No database folders found in $RESTORE_DIR"
  echo "Expected: $RESTORE_DIR/dbname1/ $RESTORE_DIR/dbname2/ or $RESTORE_DIR/dump/dbname1/ ..."
  exit 1
fi

echo "Restoring from $DUMP_PATH (mapped from $RESTORE_DIR)..."

docker compose run --rm \
  -v "$RESTORE_DIR:/restore:ro" \
  mongodb \
  mongorestore \
  --host mongodb \
  --port 27017 \
  --username "$MONGO_CC_ADMIN_USER" \
  --password "$MONGO_CC_ADMIN_PASSWORD" \
  --authenticationDatabase admin \
  --drop \
  "$DUMP_PATH"

echo "Restore complete."
