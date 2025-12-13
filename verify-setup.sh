#!/bin/bash
echo "=== Final OpenBao Verification ==="

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Use the token from the environment variable, or prompt for it
TOKEN="${VAULT_TOKEN}"
if [ -z "$TOKEN" ]; then
    echo "VAULT_TOKEN not found in .env file or environment variables."
    read -sp "Please paste your root token: " TOKEN
    echo
fi

echo "1. Testing token..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --header "X-Vault-Token: $TOKEN" http://localhost:8200/v1/auth/token/lookup-self)
if [ "$RESPONSE" = "200" ]; then
    echo "   ✅ Token is valid."
else
    echo "   ❌ Token is invalid (HTTP Code: $RESPONSE). Please check the logs for the correct token."
    exit 1
fi

echo "2. Enabling KV secrets engine at path 'ehr'..."
curl -s --header "X-Vault-Token: $TOKEN" --request POST \
  --data '{"type":"kv", "options": {"version": "2"}}' \
  http://localhost:8200/v1/sys/mounts/ehr

echo "3. Writing a test secret..."
curl -s --header "X-Vault-Token: $TOKEN" --header "Content-Type: application/json" --request POST \
  --data '{"data": {"db_password": "super-secret-ehr-password"}}' \
  http://localhost:8200/v1/ehr/data/mongodb

echo "4. Reading the test secret..."
curl -s --header "X-Vault-Token: $TOKEN" http://localhost:8200/v1/ehr/data/mongodb | python3 -m json.tool

echo ""
echo "=== Setup Successful! ==="
echo "OpenBao is ready. You can now access the UI at http://localhost:8200"
echo "Use this token to log in: $TOKEN"
