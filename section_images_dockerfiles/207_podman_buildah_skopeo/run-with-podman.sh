#!/bin/bash
set -e

# Script to run the MonsterStack application with Podman
# This demonstrates how to run a multi-container application with Podman

IMAGE_NAME="${IMAGE_NAME:-monsterstack:buildah}"
NETWORK_NAME="monster_network"

echo "=== Starting MonsterStack with Podman ==="
echo ""

# Clean up any existing containers
echo "Cleaning up existing containers..."
podman rm -f monsterstack-frontend monsterstack-redis monsterstack-imagebackend 2>/dev/null || true

# Create network if it doesn't exist
echo "Creating network..."
podman network exists ${NETWORK_NAME} || podman network create ${NETWORK_NAME}

# Start Redis
echo "Starting Redis..."
podman run -d \
  --name monsterstack-redis \
  --network ${NETWORK_NAME} \
  redis:alpine

# Start imagebackend
echo "Starting imagebackend (dnmonster)..."
podman run -d \
  --name monsterstack-imagebackend \
  --network ${NETWORK_NAME} \
  amouat/dnmonster:1.0

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 2

# Start frontend
echo "Starting frontend..."
podman run -d \
  --name monsterstack-frontend \
  --network ${NETWORK_NAME} \
  -p 5000:5000 \
  -e CONTEXT=PROD \
  -e REDIS_DOMAIN=monsterstack-redis \
  -e IMAGEBACKEND_DOMAIN=monsterstack-imagebackend \
  ${IMAGE_NAME}

# Wait for frontend to be ready
echo "Waiting for frontend to be ready..."
sleep 3

echo ""
echo "=== MonsterStack is running! ==="
echo ""
echo "Services:"
echo "  - Frontend:     http://localhost:5000"
echo "  - Redis:        monsterstack-redis (internal)"
echo "  - ImageBackend: monsterstack-imagebackend (internal)"
echo ""
echo "To view logs:"
echo "  podman logs -f monsterstack-frontend"
echo ""
echo "To check status:"
echo "  podman ps"
echo ""
echo "To stop all:"
echo "  podman stop monsterstack-frontend monsterstack-redis monsterstack-imagebackend"
echo "  podman rm monsterstack-frontend monsterstack-redis monsterstack-imagebackend"
echo ""
echo "Testing the application..."
curl -s http://localhost:5000 > /dev/null && echo "✓ Application is responding!" || echo "⚠ Application not responding yet, wait a few seconds"
