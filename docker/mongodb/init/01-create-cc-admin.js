// Create Credit Control admin user (runs on first MongoDB start when data dir is empty)
// User and password from MONGO_CC_ADMIN_USER and MONGO_CC_ADMIN_PASSWORD env vars

const user = process.env.MONGO_CC_ADMIN_USER || 'ccDevAdm';
const pwd = process.env.MONGO_CC_ADMIN_PASSWORD;

if (!pwd) {
  throw new Error('MONGO_CC_ADMIN_PASSWORD must be set in .env for Credit Control API');
}

db.getSiblingDB("admin").createUser({
  user,
  pwd,
  roles: [
    { role: "userAdminAnyDatabase", db: "admin" },
    { role: "readWriteAnyDatabase", db: "admin" },
    { role: "dbAdminAnyDatabase", db: "admin" }
  ]
});
