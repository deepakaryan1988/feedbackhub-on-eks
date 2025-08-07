#!/bin/bash

# Build and deploy script for FeedbackHub on EKS
# Usage: ./scripts/build-eks.sh [tag] [environment]

set -e

# Default values
TAG=${1:-latest}
ENVIRONMENT=${2:-development}
AWS_REGION=${AWS_REGION:-ap-south-1}
ECR_REGISTRY=${ECR_REGISTRY:-"your-account-id.dkr.ecr.ap-south-1.amazonaws.com"}
IMAGE_NAME="feedbackhub"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Building and deploying FeedbackHub to EKS${NC}"
echo -e "${YELLOW}Environment: $ENVIRONMENT${NC}"
echo -e "${YELLOW}Tag: $TAG${NC}"
echo -e "${YELLOW}AWS Region: $AWS_REGION${NC}"
echo ""

# Step 1: Build Docker image
echo -e "${YELLOW}📦 Step 1: Building Docker image...${NC}"
docker build -f docker/Dockerfile.prod -t ${IMAGE_NAME}:${TAG} .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker image built successfully!${NC}"
else
    echo -e "${RED}❌ Docker build failed!${NC}"
    exit 1
fi

# Step 2: Tag for ECR
echo -e "${YELLOW}🏷️  Step 2: Tagging image for ECR...${NC}"
docker tag ${IMAGE_NAME}:${TAG} ${ECR_REGISTRY}/${IMAGE_NAME}:${TAG}
docker tag ${IMAGE_NAME}:${TAG} ${ECR_REGISTRY}/${IMAGE_NAME}:${ENVIRONMENT}

# Step 3: Login to ECR
echo -e "${YELLOW}🔐 Step 3: Logging into ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ ECR login successful!${NC}"
else
    echo -e "${RED}❌ ECR login failed!${NC}"
    exit 1
fi

# Step 4: Push to ECR
echo -e "${YELLOW}📤 Step 4: Pushing image to ECR...${NC}"
docker push ${ECR_REGISTRY}/${IMAGE_NAME}:${TAG}
docker push ${ECR_REGISTRY}/${IMAGE_NAME}:${ENVIRONMENT}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Image pushed to ECR successfully!${NC}"
else
    echo -e "${RED}❌ ECR push failed!${NC}"
    exit 1
fi

# Step 5: Update Kubernetes deployment (if kubectl is available)
if command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}🔄 Step 5: Updating Kubernetes deployment...${NC}"
    
    # Check if deployment exists
    if kubectl get deployment feedbackhub -n feedbackhub-${ENVIRONMENT} &> /dev/null; then
        kubectl set image deployment/feedbackhub feedbackhub=${ECR_REGISTRY}/${IMAGE_NAME}:${TAG} -n feedbackhub-${ENVIRONMENT}
        kubectl rollout status deployment/feedbackhub -n feedbackhub-${ENVIRONMENT}
        echo -e "${GREEN}✅ Kubernetes deployment updated!${NC}"
    else
        echo -e "${YELLOW}⚠️ Kubernetes deployment not found. Deploy using Helm first.${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ kubectl not found. Skipping Kubernetes deployment update.${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Build and deploy completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "Image: ${ECR_REGISTRY}/${IMAGE_NAME}:${TAG}"
echo "Environment: ${ENVIRONMENT}"
echo "Region: ${AWS_REGION}"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "1. Deploy using Helm: helm upgrade --install feedbackhub ./helm/feedbackhub"
echo "2. Check pods: kubectl get pods -n feedbackhub-${ENVIRONMENT}"
echo "3. Check logs: kubectl logs -f deployment/feedbackhub -n feedbackhub-${ENVIRONMENT}"
echo "4. Test health: kubectl port-forward svc/feedbackhub 3000:3000 -n feedbackhub-${ENVIRONMENT}"
