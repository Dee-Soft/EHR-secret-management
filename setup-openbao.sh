#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== EHR Secret Management Setup ===${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

# Check if network exists, create if not
if ! docker network inspect secrets_net > /dev/null 2>&1; then
    echo "Creating Docker network: secrets_net..."
    docker network create secrets_net
    echo -e "${GREEN}✓ Network created${NC}"
else
    echo -e "${GREEN}✓ Network already exists${NC}"
fi

# Pull latest images
echo "Pulling Docker images..."
docker-compose -f docker-compose-secrets.yml pull

# Start services
echo "Starting OpenBao and MongoDB..."
docker-compose -f docker-compose-secrets.yml up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10

# Check MongoDB health
if docker-compose -f docker-compose-secrets.yml exec mongodb_vault echo "MongoDB ready" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ MongoDB is running${NC}"
else
    echo -e "${RED}✗ MongoDB failed to start${NC}"
    exit 1
fi

# Wait for OpenBao to initialize
echo "Waiting for OpenBao to initialize..."
sleep 15

# Check OpenBao status
if docker-compose -f docker-compose-secrets.yml exec openbao openbao status > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OpenBao is running${NC}"
else
    echo -e "${RED}✗ OpenBao failed to start${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "OpenBao Dashboard: http://localhost:8200"
echo ""
echo "Next steps:"
echo "1. Initialize OpenBao"
echo "2. Unseal OpenBao"
echo "3. Configure authentication"
echo ""
echo "To initialize OpenBao, run:"
echo "  docker-compose -f docker-compose-secrets.yml exec openbao openbao operator init"
