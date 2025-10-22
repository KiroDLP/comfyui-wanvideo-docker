#!/bin/bash
set -e

# ComfyUI WanVideo Docker - Build and Push Script for GHCR
# This script builds and pushes your Docker image to GitHub Container Registry

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="comfyui-wanvideo"
GHCR_REGISTRY="ghcr.io"

echo "======================================"
echo "ComfyUI WanVideo - Build & Push"
echo "======================================"
echo ""

# Get GitHub username
if [ -z "$GITHUB_USERNAME" ]; then
    read -p "Enter your GitHub username: " GITHUB_USERNAME
fi

if [ -z "$GITHUB_USERNAME" ]; then
    echo -e "${RED}Error: GitHub username is required${NC}"
    exit 1
fi

FULL_IMAGE_NAME="${GHCR_REGISTRY}/${GITHUB_USERNAME}/${IMAGE_NAME}"

# Check if logged into GHCR
echo -e "${YELLOW}Checking GHCR login status...${NC}"
if ! docker login ${GHCR_REGISTRY} --get-login 2>/dev/null | grep -q "${GITHUB_USERNAME}"; then
    echo -e "${YELLOW}Not logged into GHCR. Please login:${NC}"
    echo ""
    echo "You'll need a GitHub Personal Access Token with 'write:packages' scope"
    echo "Create one at: https://github.com/settings/tokens"
    echo ""
    read -p "Enter your GitHub token: " -s GITHUB_TOKEN
    echo ""

    if [ -z "$GITHUB_TOKEN" ]; then
        echo -e "${RED}Error: GitHub token is required${NC}"
        exit 1
    fi

    echo "$GITHUB_TOKEN" | docker login ${GHCR_REGISTRY} -u ${GITHUB_USERNAME} --password-stdin

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to login to GHCR${NC}"
        exit 1
    fi

    echo -e "${GREEN}Successfully logged into GHCR${NC}"
else
    echo -e "${GREEN}Already logged into GHCR${NC}"
fi

echo ""

# Ask for build options
echo "Build options:"
echo "1. Quick build (use cache)"
echo "2. Full rebuild (--no-cache)"
read -p "Choose option [1]: " BUILD_OPTION
BUILD_OPTION=${BUILD_OPTION:-1}

BUILD_ARGS=""
if [ "$BUILD_OPTION" = "2" ]; then
    BUILD_ARGS="--no-cache"
    echo -e "${YELLOW}Building with --no-cache (this will take longer)${NC}"
else
    echo -e "${YELLOW}Building with cache${NC}"
fi

echo ""

# Build the image
echo -e "${YELLOW}Step 1/3: Building Docker image...${NC}"
echo "Image will be tagged as: ${FULL_IMAGE_NAME}:latest"
echo ""

DOCKER_BUILDKIT=1 docker build $BUILD_ARGS \
    -t ${IMAGE_NAME}:latest \
    -t ${FULL_IMAGE_NAME}:latest \
    .

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Build completed successfully!${NC}"
echo ""

# Show image size
IMAGE_SIZE=$(docker images ${IMAGE_NAME}:latest --format "{{.Size}}")
echo "Image size: ${IMAGE_SIZE}"
echo ""

# Ask if user wants to push
read -p "Push to GHCR now? [Y/n]: " PUSH_CONFIRM
PUSH_CONFIRM=${PUSH_CONFIRM:-Y}

if [[ ! $PUSH_CONFIRM =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Skipping push. Image is built locally as:${NC}"
    echo "  - ${IMAGE_NAME}:latest"
    echo "  - ${FULL_IMAGE_NAME}:latest"
    echo ""
    echo "To push later, run:"
    echo "  docker push ${FULL_IMAGE_NAME}:latest"
    exit 0
fi

# Push to GHCR
echo ""
echo -e "${YELLOW}Step 2/3: Pushing to GHCR...${NC}"
docker push ${FULL_IMAGE_NAME}:latest

if [ $? -ne 0 ]; then
    echo -e "${RED}Push failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Successfully pushed to GHCR!${NC}"
echo ""

# Final instructions
echo "======================================"
echo -e "${GREEN}Success! Next steps:${NC}"
echo "======================================"
echo ""
echo "1. Make your image public (if not already):"
echo "   - Go to: https://github.com/${GITHUB_USERNAME}?tab=packages"
echo "   - Click: ${IMAGE_NAME}"
echo "   - Package settings → Change visibility → Public"
echo ""
echo "2. Use in RunPod template:"
echo "   Container Image: ${FULL_IMAGE_NAME}:latest"
echo ""
echo "3. Test locally (optional):"
echo "   docker run --gpus all -p 8188:8188 ${FULL_IMAGE_NAME}:latest"
echo ""
