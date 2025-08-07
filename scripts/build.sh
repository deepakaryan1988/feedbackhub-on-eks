#!/bin/bash

# Build script for FeedbackHub Docker image
# Usage: ./scripts/build.sh [tag]

set -e

# Default tag
TAG=${1:-latest}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building FeedbackHub Docker image...${NC}"

# Build the Docker image
docker build -f docker/Dockerfile.prod -t feedbackhub:${TAG} .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker image built successfully!${NC}"
    echo -e "${GREEN}Image: feedbackhub:${TAG}${NC}"
    echo ""
    echo -e "${YELLOW}To run the container:${NC}"
    echo "docker run -p 3000:3000 -e MONGODB_URI='your-mongodb-uri' feedbackhub:${TAG}"
    echo ""
    echo -e "${YELLOW}Or use Docker Compose:${NC}"
    echo "docker-compose up -d"
else
    echo -e "${RED}❌ Docker build failed!${NC}"
    exit 1
fi 