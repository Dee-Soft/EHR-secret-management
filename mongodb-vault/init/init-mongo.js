db = db.getSiblingDB('openbao');
db.createUser({
  user: "openbao_user",
  pwd: "SecurePassword123!",
  roles: [
    { role: "readWrite", db: "openbao" },
    { role: "dbAdmin", db: "openbao" }
  ]
});
print("MongoDB initialized");
