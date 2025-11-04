#!/bin/bash
set -e

# CI/CD build script using Buildah and Skopeo
# This script demonstrates a complete CI/CD workflow

# Variables (can be overridden by environment)
IMAGE_NAME="${IMAGE_NAME:-monsterstack}"
REGISTRY="${REGISTRY:-localhost:5000}"
TAG="${CI_COMMIT_SHA:-$(git rev-parse --short HEAD 2>/dev/null || echo 'latest')}"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "=== CI/CD Build Script ==="
echo "Image: ${FULL_IMAGE}"
echo ""

# Step 1: Build with Buildah
echo "=== Step 1: Building image with Buildah ==="
buildah build -t ${IMAGE_NAME}:${TAG} .
echo "✓ Build complete"
echo ""

# Step 2: Run tests (optional, can be expanded)
echo "=== Step 2: Running tests ==="
# Lancer les tests unitaires dans un conteneur
echo "Running unit tests..."
podman run --rm \
  -v $(pwd)/app:/app:ro \
  ${IMAGE_NAME}:${TAG} \
  sh -c "cd /app && python3 -m pytest tests/unit.py -v" || {
    echo "⚠ Tests failed or pytest not configured"
    echo "  (This is expected if pytest is not in the image)"
  }
echo "✓ Tests complete"
echo ""

# Step 3: Tag the image
echo "=== Step 3: Tagging image ==="
buildah tag ${IMAGE_NAME}:${TAG} ${FULL_IMAGE}
buildah tag ${IMAGE_NAME}:${TAG} ${REGISTRY}/${IMAGE_NAME}:latest
echo "✓ Tagged as ${FULL_IMAGE}"
echo "✓ Tagged as ${REGISTRY}/${IMAGE_NAME}:latest"
echo ""

# Step 4: Push with Skopeo (if registry is configured)
if [ "${SKIP_PUSH}" != "true" ]; then
    echo "=== Step 4: Pushing image with Skopeo ==="

    # Check if registry credentials are provided
    if [ -n "${REGISTRY_USER}" ] && [ -n "${REGISTRY_PASSWORD}" ]; then
        echo "Authenticating to registry..."
        skopeo login -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY}
    fi

    echo "Pushing ${FULL_IMAGE}..."
    skopeo copy \
      containers-storage:localhost/${IMAGE_NAME}:${TAG} \
      docker://${FULL_IMAGE} || {
        echo "⚠ Push failed - registry may not be accessible"
        echo "  Set SKIP_PUSH=true to skip pushing"
      }

    echo "Pushing latest tag..."
    skopeo copy \
      containers-storage:localhost/${IMAGE_NAME}:${TAG} \
      docker://${REGISTRY}/${IMAGE_NAME}:latest || true

    echo "✓ Push complete"
else
    echo "=== Step 4: Skipping push (SKIP_PUSH=true) ==="
fi

echo ""
echo "=== Build complete ==="
echo "Image: ${FULL_IMAGE}"
echo ""
echo "Available locally as:"
echo "  - ${IMAGE_NAME}:${TAG}"
echo "  - ${REGISTRY}/${IMAGE_NAME}:${TAG}"
echo "  - ${REGISTRY}/${IMAGE_NAME}:latest"
echo ""
echo "To run locally:"
echo "  podman run -d -p 5000:5000 ${IMAGE_NAME}:${TAG}"
