#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Verifying Secret Management Setup ===${NC}"

# Check Docker network
echo "1. Checking Docker network..."
if docker network inspect secrets_net > /dev/null 2>&1; then
    echo -e "   ${GREEN}✓ secrets_net network exists${NC}"
else
    echo -e "   ${RED}✗ secrets_net network not found${NC}"
    exit 1
fi

# Check MongoDB container
echo "2. Checking MongoDB..."
if docker ps --filter "name=mongodb_vault" --format "{{.Names}}" | grep -q "mongodb_vault"; then
    echo -e "   ${GREEN}✓ MongoDB container is running${NC}"
    
    # Check MongoDB connectivity
    if docker-compose -f docker-compose-secrets.yml exec mongodb_vault mongosh --quiet --eval "db.runCommand('ping').ok" 2>/dev/null | grep -q "1"; then
        echo -e "   ${GREEN}✓ MongoDB is responding${NC}"
    else
        echo -e "   ${RED}✗ MongoDB not responding${NC}"
    fi
else
    echo -e "   ${RED}✗ MongoDB container not found${NC}"
fi

# Check OpenBao container
echo "3. Checking OpenBao..."
if docker ps --filter "name=openbao" --format "{{.Names}}" | grep -q "openbao"; then
    echo -e "   ${GREEN}✓ OpenBao container is running${NC}"
    
    # Check OpenBao status
    STATUS_OUTPUT=$(docker-compose -f docker-compose-secrets.yml exec openbao openbao status -format=json 2>/dev/null || true)
    
    if echo "$STATUS_OUTPUT" | grep -q '"initialized":true'; then
        echo -e "   ${GREEN}✓ OpenBao is initialized${NC}"
    else
        echo -e "   ${YELLOW}⚠ OpenBao not initialized${NC}"
    fi
    
    if echo "$STATUS_OUTPUT" | grep -q '"sealed":false'; then
        echo -e "   ${GREEN}✓ OpenBao is unsealed${NC}"
    else
        echo -e "   ${YELLOW}⚠ OpenBao is sealed${NC}"
    fi
else
    echo -e "   ${RED}✗ OpenBao container not found${NC}"
fi

# Check ports
echo "4. Checking network ports..."
if netstat -tuln 2>/dev/null | grep -q ":8200"; then
    echo -e "   ${GREEN}✓ Port 8200 (OpenBao) is listening${NC}"
else
    echo -e "   ${YELLOW}⚠ Port 8200 not listening${NC}"
fi

if netstat -tuln 2>/dev/null | grep -q ":27017"; then
    echo -e "   ${GREEN}✓ Port 27017 (MongoDB) is listening${NC}"
else
    echo -e "   ${YELLOW}⚠ Port 27017 not listening${NC}"
fi

echo ""
echo -e "${YELLOW}=== Summary ===${NC}"
echo "OpenBao URL: http://localhost:8200"
echo "MongoDB Port: 27017"
echo "Docker Network: secrets_net"
echo ""
echo "To access OpenBao UI:"
echo "  Open http://localhost:8200 in your browser"
echo ""
echo "To check OpenBao status:"
echo "  docker-compose -f docker-compose-secrets.yml exec openbao openbao status"
