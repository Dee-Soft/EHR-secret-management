#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== OpenBao Initialization ===${NC}"

# Check if OpenBao is running
if ! docker-compose -f docker-compose-simple.yml exec openbao openbao status > /dev/null 2>&1; then
    echo -e "${RED}Error: OpenBao is not running${NC}"
    echo "Start OpenBao first: docker-compose -f docker-compose-simple.yml up -d"
    exit 1
fi

# Initialize OpenBao
echo "Initializing OpenBao..."
INIT_OUTPUT=$(docker-compose -f docker-compose-simple.yml exec openbao openbao operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json 2>/dev/null)

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to initialize OpenBao. It may already be initialized.${NC}"
    echo "Check status: docker-compose -f docker-compose-simple.yml exec openbao openbao status"
    exit 1
fi

# Parse JSON output
ROOT_TOKEN=$(echo $INIT_OUTPUT | grep -o '"root_token":"[^"]*"' | cut -d'"' -f4)
UNSEAL_KEYS_JSON=$(echo $INIT_OUTPUT | grep -o '"keys":\[[^]]*\]' | sed 's/"keys":\[//' | sed 's/\]//' | tr -d '"')
KEYS_BASE64=$(echo $INIT_OUTPUT | grep -o '"keys_base64":\[[^]]*\]' | sed 's/"keys_base64":\[//' | sed 's/\]//' | tr -d '"')

# Convert to arrays
IFS=',' read -ra UNSEAL_KEYS <<< "$UNSEAL_KEYS_JSON"
IFS=',' read -ra KEYS_BASE64_ARRAY <<< "$KEYS_BASE64"

# Save keys to file (SECURE LOCATION - for development only!)
mkdir -p ./secrets
echo "root_token: $ROOT_TOKEN" > ./secrets/openbao-keys.txt
echo "" >> ./secrets/openbao-keys.txt
echo "Unseal Keys:" >> ./secrets/openbao-keys.txt
for i in "${!UNSEAL_KEYS[@]}"; do
    echo "Key $((i+1)): ${UNSEAL_KEYS[$i]}" >> ./secrets/openbao-keys.txt
    echo "Key $((i+1)) (base64): ${KEYS_BASE64_ARRAY[$i]}" >> ./secrets/openbao-keys.txt
done

echo -e "${GREEN}✓ OpenBao initialized successfully${NC}"
echo ""
echo -e "${YELLOW}=== IMPORTANT SECURITY INFORMATION ===${NC}"
echo ""
echo "Root Token: $ROOT_TOKEN"
echo ""
echo "Unseal Keys (save these securely):"
for i in "${!UNSEAL_KEYS[@]}"; do
    echo "  Key $((i+1)): ${UNSEAL_KEYS[$i]}"
done
echo ""
echo -e "${RED}WARNING: These keys are saved in ./secrets/openbao-keys.txt${NC}"
echo -e "${RED}         DELETE THIS FILE IN PRODUCTION!${NC}"
echo ""
echo -e "${YELLOW}=== Unsealing OpenBao ===${NC}"

# Unseal with first 3 keys
echo "Unsealing with key 1..."
docker-compose -f docker-compose-secrets.yml exec openbao openbao operator unseal "${UNSEAL_KEYS[0]}" > /dev/null 2>&1

echo "Unsealing with key 2..."
docker-compose -f docker-compose-secrets.yml exec openbao openbao operator unseal "${UNSEAL_KEYS[1]}" > /dev/null 2>&1

echo "Unsealing with key 3..."
docker-compose -f docker-compose-secrets.yml exec openbao openbao operator unseal "${UNSEAL_KEYS[2]}" > /dev/null 2>&1

# Check status
STATUS=$(docker-compose -f docker-compose-secrets.yml exec openbao openbao status -format=json 2>/dev/null | grep -o '"sealed":false')
if [[ $STATUS == '"sealed":false' ]]; then
    echo -e "${GREEN}✓ OpenBao is unsealed and ready${NC}"
else
    echo -e "${RED}✗ OpenBao failed to unseal${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== OpenBao Ready ===${NC}"
echo "OpenBao URL: http://localhost:8200"
echo "Root Token: $ROOT_TOKEN"
echo ""
echo "Test connection:"
echo "  docker-compose -f docker-compose-secrets.yml exec openbao openbao token lookup"
