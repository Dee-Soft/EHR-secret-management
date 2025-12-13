#!/bin/bash

echo "=== Setup OpenBao ==="
# Create directories
echo "Creating directories..."
mkdir -p openbao/data mongodb-vault/{data,init}
chmod 777 openbao/data mongodb-vault/data

# Create MongoDB init script
cat > mongodb-vault/init/init-mongo.js << 'MONGOEOF'
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
MONGOEOF

# Create network if not exists
if ! docker network inspect secrets_net > /dev/null 2>&1; then
    echo "Creating Docker network: secrets_net..."
    docker network create secrets_net
fi

# Start services
echo "Starting services..."
docker-compose -f docker-compose-secrets.yml up -d

# Wait and check
sleep 10

echo ""
echo "=== Setup Complete ==="
echo "OpenBao UI: http://localhost:8200"
echo "Login token: $VAULT_TOKEN"
echo ""
echo "MongoDB Port: 27018"
echo "Test MongoDB: mongosh -u admin -p AdminSecurePassword123! --port 27018"
echo ""
echo "To test OpenBao:"
echo "  openbao login $VAULT_TOKEN"
echo "  openbao secrets list"
