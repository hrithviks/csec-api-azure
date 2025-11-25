#!/bin/bash
#
# This script builds the custom Ubuntu Docker image with Terraform/Azure CLI,
# tags it for GitHub Container Registry (GHCR), and pushes it.
#
# It requires the following environment variables to be set:
# - GH_USER: Your GitHub username or organization name.
# - GH_TOKEN: A GitHub Personal Access Token (PAT) with 'write:packages' scope.

# Exit immediately if a command exits with a non-zero status.
set -e

# Configuration
IMAGE_NAME="csb-terraform-agent"
IMAGE_TAG="latest"
DOCKER_CONTEXT_PATH="./ubuntu" # Path to the directory with the Dockerfile

# Check if required environment variables are set.
echo "Performing pre-build checks..."
if [ -z "$GH_USER" ] || [ -z "$GH_TOKEN" ]; then
  echo "Error: GH_USER and GH_TOKEN environment variables must be set." >&2
  exit 1
fi

# Check if the Docker context path exists.
if [ ! -d "$DOCKER_CONTEXT_PATH" ]; then
    echo "Error: Docker context path not found at '$DOCKER_CONTEXT_PATH'" >&2
    exit 1
fi

# Construct the full image reference for GHCR.
GHCR_IMAGE_REF="ghcr.io/${GH_USER}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "Authenticating with GitHub Container Registry..."
echo "${GH_TOKEN}" | docker login ghcr.io -u "${GH_USER}" --password-stdin
echo "Building Docker image..."
echo "Building and tagging image as: ${GHCR_IMAGE_REF}..."
docker build -t "${GHCR_IMAGE_REF}" "${DOCKER_CONTEXT_PATH}"
echo "Pushing image to github registry..."
docker push "${GHCR_IMAGE_REF}"
echo "Build and Push Complete: ${GHCR_IMAGE_REF}"