#!/bin/bash

# Script pour builder les images multi-architecture avec Docker Buildx
# Ce script est fourni comme exemple pour le TP

set -e

# Configuration
REGISTRY="${REGISTRY:-docker.io}"
USERNAME="${DOCKER_USERNAME:-myusername}"
BACKEND_IMAGE="${REGISTRY}/${USERNAME}/multiarch-backend"
FRONTEND_IMAGE="${REGISTRY}/${USERNAME}/multiarch-frontend"
VERSION="${VERSION:-latest}"
PLATFORMS="linux/amd64,linux/arm64"

echo "🏗️  Building multi-architecture images..."
echo "Registry: ${REGISTRY}"
echo "Platforms: ${PLATFORMS}"
echo ""

# Créer un nouveau builder si nécessaire
if ! docker buildx ls | grep -q "multiarch-builder"; then
    echo "📦 Creating new buildx builder..."
    docker buildx create --name multiarch-builder --use
    docker buildx inspect --bootstrap
else
    echo "✅ Using existing multiarch-builder"
    docker buildx use multiarch-builder
fi

# Build backend
echo ""
echo "🔨 Building backend image..."
docker buildx build \
    --platform ${PLATFORMS} \
    --tag ${BACKEND_IMAGE}:${VERSION} \
    --tag ${BACKEND_IMAGE}:latest \
    --file app/backend/Dockerfile \
    --push \
    app/backend/

echo "✅ Backend image built successfully!"

# Build frontend
echo ""
echo "🔨 Building frontend image..."
docker buildx build \
    --platform ${PLATFORMS} \
    --tag ${FRONTEND_IMAGE}:${VERSION} \
    --tag ${FRONTEND_IMAGE}:latest \
    --file app/frontend/Dockerfile \
    --push \
    app/frontend/

echo "✅ Frontend image built successfully!"

echo ""
echo "🎉 All images built and pushed successfully!"
echo ""
echo "Backend: ${BACKEND_IMAGE}:${VERSION}"
echo "Frontend: ${FRONTEND_IMAGE}:${VERSION}"
echo ""
echo "To inspect images:"
echo "  docker buildx imagetools inspect ${BACKEND_IMAGE}:${VERSION}"
echo "  docker buildx imagetools inspect ${FRONTEND_IMAGE}:${VERSION}"
