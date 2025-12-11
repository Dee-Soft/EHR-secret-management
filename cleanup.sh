#!/bin/bash

echo "=== Cleaning up OpenBao Setup ==="

# Stop and remove containers
echo "Stopping containers..."
docker-compose -f docker-compose-simple.yml down -v 2>/dev/null || true

# Remove containers if still exists
docker rm -f openbao mongodb_vault 2>/dev/null || true

# Remove network
echo "Removing network..."
docker network rm secrets_net 2>/dev/null || true

# Remove volumes
echo "Cleaning data directories..."
sudo rm -rf openbao/data mongodb-vault/data 2>/dev/null || true

echo "✓ Cleanup complete"
