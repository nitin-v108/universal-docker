# MongoDB Restore

Place your **mongodump** output here, then run `make cc-mongo-restore` from repo root.

## Structure

**Option A** – Standard mongodump (creates a `dump` folder):
```
storage/mongodb-restore/
  dump/
    your_db_1/
      collection1.bson
      collection1.metadata.json
      collection2.bson
      ...
    your_db_2/
      ...
```

**Option B** – Flattened (database folders directly here):
```
storage/mongodb-restore/
  your_db_1/
    collection1.bson
    collection1.metadata.json
    ...
  your_db_2/
    ...
```

## Export from source

On the source MongoDB server:
```bash
mongodump --uri="mongodb://user:pass@source-host:27017" --out=./mybackup
```

Then copy the contents to this folder:
- Either `mybackup/dump/*` → `storage/mongodb-restore/dump/`
- Or `mybackup/dump/db1`, `mybackup/dump/db2` → `storage/mongodb-restore/db1`, `storage/mongodb-restore/db2`

## Restore

```bash
make cc-mongo-restore
```

Uses ccDevAdm (same user as credit-control). Existing collections with the same name are dropped before restore.
