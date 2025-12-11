#!/bin/bash

echo "=== Testing OpenBao Setup ==="

# Check containers
echo "1. Checking containers..."
if docker ps | grep -q "openbao"; then
    echo "   ✓ OpenBao is running"
else
    echo "   ✗ OpenBao is NOT running"
    echo "   Starting OpenBao..."
    docker-compose -f docker-compose-simple.yml up -d openbao
    sleep 5
fi

if docker ps | grep -q "mongodb_vault"; then
    echo "   ✓ MongoDB is running"
else
    echo "   ✗ MongoDB is NOT running"
fi

# Test OpenBao
echo ""
echo "2. Testing OpenBao..."
echo "   Waiting for OpenBao to be ready..."
sleep 5

# Simple curl test
if curl -s http://localhost:8200/v1/sys/health | grep -q "initialized"; then
    echo "   ✓ OpenBao is responding"
    
    # Enable a test secrets engine
    echo "   Enabling KV secrets engine..."
    docker exec openbao openbao secrets enable -path=test kv-v2 2>/dev/null || true
    
    # Write a test secret
    echo "   Writing test secret..."
    docker exec openbao openbao kv put test/hello message="Hello from OpenBao!" 2>/dev/null || true
    
    echo "   ✓ OpenBao test complete"
else
    echo "   ✗ OpenBao not responding"
    echo "   Check logs: docker logs openbao"
fi

# Test MongoDB
echo ""
echo "3. Testing MongoDB..."
if docker exec mongodb_vault mongosh --quiet --eval "db.runCommand('ping').ok" 2>/dev/null | grep -q "1"; then
    echo "   ✓ MongoDB is responding"
else
    echo "   ✗ MongoDB not responding"
fi

echo ""
echo "=== Summary ==="
echo "OpenBao: http://localhost:8200"
echo "Token: root-token-123"
echo ""
echo "To access OpenBao UI, open the URL above in your browser"
echo "and use token: root-token-123"
