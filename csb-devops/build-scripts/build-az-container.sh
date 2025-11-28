#!/bin/bash
#
# -----------------------------------------------------------------------------
# Script      : build-az-container.sh
# Description : This script builds and pushes the custom container image used
#               as a build agent. The image is pre-configured with tools like
#               Terraform and Azure CLI.
#
# Pre-requisites:
#  1. Docker must be installed and running.
#  2. The following environment variables must be set:
#   - GH_USER: The GitHub username or organization to push the image to.
#   - GH_TOKEN: A GitHub Personal Access Token with 'write:packages' scope.
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status.
set -e
set -u
set -o pipefail

# Helper function to format log messages with a timestamp.
console_log() {
    DATE_FORMAT=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$DATE_FORMAT :: $1"
}

# Configuration
IMAGE_NAME="csec-build-container"
IMAGE_TAG="latest"
DOCKER_CONTEXT_PATH="../build-container" # Path to the directory with the Dockerfile

# Check if required environment variables are set.
console_log "Performing pre-build checks..."

[ -z "$GH_USER" ] && console_log "Error: GH_USER environment variable must be set." && exit 1
[ -z "$GH_TOKEN" ] && console_log "Error: GH_TOKEN environment variable must be set." && exit 1

# Check if the Docker context path exists.
if [ ! -d "$DOCKER_CONTEXT_PATH" ]; then
    console_log "Error: Docker context path not found at '$DOCKER_CONTEXT_PATH'"
    exit 1
fi

# Check if the Dockerfile exists in the context path.
if [ ! -f "${DOCKER_CONTEXT_PATH}/Dockerfile" ]; then
    console_log "Error: Dockerfile not found in '$DOCKER_CONTEXT_PATH'"
    exit 1
fi

console_log "Pre-build checks passed."

# Construct the full image reference for GHCR.
GHCR_IMAGE_REF="ghcr.io/${GH_USER}/${IMAGE_NAME}:${IMAGE_TAG}"

console_log "Authenticating with GitHub Container Registry..."
echo "${GH_TOKEN}" | docker login ghcr.io -u "${GH_USER}" --password-stdin
console_log "Building and tagging image as: ${GHCR_IMAGE_REF}..."
docker build -t "${GHCR_IMAGE_REF}" "${DOCKER_CONTEXT_PATH}"
console_log "Pushing image to GitHub Container Registry..."
docker push "${GHCR_IMAGE_REF}"
console_log "Build and Push Complete: ${GHCR_IMAGE_REF}"