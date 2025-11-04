#!/bin/bash
set -e

# Build script using Buildah (native scripted approach)
# This demonstrates the power of Buildah's scripted builds

echo "=== Building MonsterStack image with Buildah (scripted) ==="

# Create a working container from a base image
container=$(buildah from python:3.10)

echo "Container ID: $container"

# Create the uwsgi user and group
echo "Creating uwsgi user..."
buildah run $container groupadd -r uwsgi
buildah run $container useradd -r -g uwsgi uwsgi

# Install Python dependencies
echo "Installing Python packages..."
buildah run $container pip install Flask uWSGI requests redis

# Configure the working directory
echo "Setting up working directory..."
buildah config --workingdir /app $container

# Copy application files
echo "Copying application files..."
buildah copy $container ./app /app
buildah copy $container boot.sh /boot.sh

# Make boot.sh executable
echo "Setting permissions..."
buildah run $container chmod a+x /boot.sh

# Set environment variables
echo "Configuring environment..."
buildah config --env CONTEXT=PROD $container
buildah config --env IMAGEBACKEND_DOMAIN=imagebackend $container
buildah config --env REDIS_DOMAIN=redis $container

# Expose ports
echo "Exposing ports..."
buildah config --port 5000 --port 9191 $container

# Set the user
echo "Setting user to uwsgi..."
buildah config --user uwsgi $container

# Set the default command
echo "Setting default command..."
buildah config --cmd '/boot.sh' $container

# Commit the container to an image
echo "Committing container to image..."
buildah commit $container monsterstack:buildah-scripted

# Clean up the working container
echo "Cleaning up..."
buildah rm $container

echo "=== Build complete ==="
echo "Image: monsterstack:buildah-scripted"
echo ""
echo "To run the image:"
echo "  podman run -d -p 5000:5000 --name monsterstack monsterstack:buildah-scripted"
echo ""
echo "To view the image:"
echo "  podman images | grep monsterstack"
