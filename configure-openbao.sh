#!/bin/bash

echo "=== Configuring OpenBao for EHR System ==="

# Set these variables
VAULT_ADDR="http://localhost:8200"
VAULT_TOKEN="s.ZlQFmE4R60IuiSWq0uC5xhiI"  # Replace with your actual token

if [ "$VAULT_TOKEN" = "YOUR_ROOT_TOKEN_HERE" ]; then
    echo "ERROR: Please edit this script and set VAULT_TOKEN to your actual root token"
    exit 1
fi

echo "1. Enabling Transit Secrets Engine..."
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"type":"transit"}' \
  $VAULT_ADDR/v1/sys/mounts/transit

echo "2. Creating Transit Keys for EHR..."
# RSA key for key exchange (frontend-backend)
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"type":"rsa-2048", "exportable": true}' \
  $VAULT_ADDR/v1/transit/keys/ehr-rsa-exchange

# AES master key for generating data keys
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"type":"aes256-gcm96", "derived": true}' \
  $VAULT_ADDR/v1/transit/keys/ehr-aes-master

echo "3. Configuring automatic key rotation..."
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"auto_rotate_period":"720h"}' \
  $VAULT_ADDR/v1/transit/keys/ehr-rsa-exchange/config

curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"auto_rotate_period":"2160h"}' \
  $VAULT_ADDR/v1/transit/keys/ehr-aes-master/config

echo "4. Creating policy for backend access..."
cat > backend-policy.hcl << 'POLICYEOF'
# Backend policy for EHR system
path "transit/encrypt/ehr-rsa-exchange" {
  capabilities = ["create", "update"]
}

path "transit/decrypt/ehr-rsa-exchange" {
  capabilities = ["create", "update"]
}

path "transit/datakey/plaintext/ehr-aes-master" {
  capabilities = ["create", "update"]
}

path "transit/encrypt/ehr-aes-master" {
  capabilities = ["create", "update"]
}

path "transit/decrypt/ehr-aes-master" {
  capabilities = ["create", "update"]
}

path "transit/keys/*" {
  capabilities = ["read"]
}

# KV storage for configuration
path "ehr/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
POLICYEOF

# Create the policy in OpenBao
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data "{\"policy\": \"$(cat backend-policy.hcl | sed ':a;N;$!ba;s/\n/\\n/g')\"}" \
  $VAULT_ADDR/v1/sys/policies/acl/backend-policy

echo "5. Setting up AppRole for backend (production auth)..."
# Enable AppRole auth method
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"type":"approle"}' \
  $VAULT_ADDR/v1/sys/auth/approle

# Create AppRole for backend
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data '{"token_policies":"backend-policy"}' \
  $VAULT_ADDR/v1/auth/approle/role/backend-role

# Get Role ID
ROLE_ID=$(curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  $VAULT_ADDR/v1/auth/approle/role/backend-role/role-id | \
  python3 -c "import sys,json; print(json.load(sys.stdin)['data']['role_id'])")

# Generate Secret ID
SECRET_ID=$(curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  $VAULT_ADDR/v1/auth/approle/role/backend-role/secret-id | \
  python3 -c "import sys,json; print(json.load(sys.stdin)['data']['secret_id'])")

echo "6. Storing EHR MongoDB credentials..."
# Store your EHR database credentials (replace with your actual connection string)
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --header "Content-Type: application/json" \
  --request POST \
  --data '{"data": {"connection_string": "mongodb://mongoDB:27017/EhrDB"}}' \
  $VAULT_ADDR/v1/ehr/data/mongodb/config

echo ""
echo "=== Configuration Complete! ==="
echo ""
echo "Important Credentials:"
echo "----------------------"
echo "AppRole Role ID:    $ROLE_ID"
echo "AppRole Secret ID:  $SECRET_ID"
echo ""
echo "Save these for your backend configuration!"
echo ""
echo "Test commands:"
echo "--------------"
echo "1. Generate a test data key:"
echo "   curl --header \"X-Vault-Token: \$VAULT_TOKEN\" \\"
echo "     --request POST \\"
echo "     $VAULT_ADDR/v1/transit/datakey/plaintext/ehr-aes-master"
echo ""
echo "2. Test encryption:"
echo "   curl --header \"X-Vault-Token: \$VAULT_TOKEN\" \\"
echo "     --header \"Content-Type: application/json\" \\"
echo "     --request POST \\"
echo "     --data '{\"plaintext\": \"$(echo -n 'test data' | base64)\"}' \\"
echo "     $VAULT_ADDR/v1/transit/encrypt/ehr-aes-master"
