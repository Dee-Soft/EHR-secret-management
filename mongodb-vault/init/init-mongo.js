// MongoDB initialization for OpenBao
db = db.getSiblingDB('openbao');

// Create dedicated user for OpenBao
db.createUser({
  user: "openbao_user",
  pwd: "SecurePassword123!", // CHANGE THIS IN PRODUCTION
  roles: [
    { role: "readWrite", db: "openbao" },
    { role: "dbAdmin", db: "openbao" }
  ]
});

// Create indexes for better performance
db.vault_storage.createIndex({ "key": 1 }, { unique: true });
db.vault_storage.createIndex({ "timestamp": 1 });

print("MongoDB initialized for OpenBao storage");
