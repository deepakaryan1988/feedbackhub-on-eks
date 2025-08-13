#!/bin/bash

# Build and Push FeedbackHub to ECR for ARM64 (EKS Graviton)
# Usage: ./scripts/build-and-push-ecr.sh [tag]

set -e

# Default tag
TAG=${1:-v0.1.0}

# Set variables
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [[ -z "$ACCOUNT_ID" ]]; then
    echo "❌ Failed to retrieve AWS account ID. Please check your AWS credentials and permissions." >&2
    exit 1
fi

REGION=us-east-1
REPO=feedbackhub-web
IMAGE=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO:$TAG

echo "🚀 Building and pushing FeedbackHub to ECR for ARM64 (EKS Graviton)..."
echo "Account ID: $ACCOUNT_ID"
echo "Region: $REGION"
echo "Repository: $REPO"
echo "Tag: $TAG"
echo "Image: $IMAGE"
echo "Architecture: ARM64 (linux/arm64)"
echo ""

# Step 1: Build Next.js application
echo "📦 Building Next.js application..."
npm run build

# Step 2: Build Docker image for ARM64 (EKS Graviton)
echo "🐳 Building Docker image for ARM64 (EKS Graviton)..."
docker build --platform linux/arm64 -f docker/Dockerfile.prod -t $IMAGE .

# Step 3: Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Step 4: Push to ECR
echo "⬆️  Pushing image to ECR..."
docker push $IMAGE

# Step 5: Verify
echo "✅ Verifying push..."
aws ecr describe-images --repository-name $REPO --region $REGION --query 'imageDetails[].imageTags' --output table

echo ""
echo "🎉 Success! Image pushed to ECR:"
echo "   $IMAGE"
echo ""
echo "💡 Use this image in your Kubernetes deployment!"
