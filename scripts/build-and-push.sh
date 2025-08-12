#!/bin/bash

# Build and Push Script for FeedbackHub Docker Images
# This script builds Docker images and pushes them to ECR for EKS deployment

set -e

# Configuration
ECR_REPOSITORY="${ECR_REPOSITORY:-feedbackhub}"
AWS_REGION="${AWS_REGION:-us-east-1}"
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD)}"
LATEST_TAG="latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed or not in PATH"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured or invalid"
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Function to get ECR login token
ecr_login() {
    print_status "Logging into ECR..."
    
    # Get ECR login token
    ECR_LOGIN_TOKEN=$(aws ecr get-login-password --region $AWS_REGION)
    
    # Login to ECR
    echo $ECR_LOGIN_TOKEN | docker login --username AWS --password-stdin $ECR_REPOSITORY.dkr.ecr.$AWS_REGION.amazonaws.com
    
    print_status "Successfully logged into ECR"
}

# Function to build Docker image
build_image() {
    local dockerfile=$1
    local tag=$2
    
    print_status "Building Docker image with tag: $tag"
    
    # Build the image
    docker build -f $dockerfile -t $tag .
    
    if [ $? -eq 0 ]; then
        print_status "Successfully built image: $tag"
    else
        print_error "Failed to build image: $tag"
        exit 1
    fi
}

# Function to tag and push image to ECR
push_to_ecr() {
    local local_tag=$1
    local ecr_tag=$2
    
    print_status "Tagging image for ECR: $ecr_tag"
    
    # Tag the image for ECR
    docker tag $local_tag $ecr_tag
    
    print_status "Pushing image to ECR: $ecr_tag"
    
    # Push to ECR
    docker push $ecr_tag
    
    if [ $? -eq 0 ]; then
        print_status "Successfully pushed image to ECR: $ecr_tag"
    else
        print_error "Failed to push image to ECR: $ecr_tag"
        exit 1
    fi
}

# Function to clean up local images
cleanup_local_images() {
    print_status "Cleaning up local images..."
    
    # Remove local images to save disk space
    docker rmi feedbackhub:$IMAGE_TAG feedbackhub:$LATEST_TAG 2>/dev/null || true
    
    print_status "Local cleanup completed"
}

# Main execution
main() {
    print_status "Starting FeedbackHub Docker build and push process"
    print_status "ECR Repository: $ECR_REPOSITORY"
    print_status "AWS Region: $AWS_REGION"
    print_status "Image Tag: $IMAGE_TAG"
    
    # Check prerequisites
    check_prerequisites
    
    # Login to ECR
    ecr_login
    
    # Build production image
    build_image "docker/Dockerfile" "feedbackhub:$IMAGE_TAG"
    build_image "docker/Dockerfile" "feedbackhub:$LATEST_TAG"
    
    # ECR repository URL
    ECR_REPO_URI="$ECR_REPOSITORY.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY"
    
    # Tag and push both tags
    push_to_ecr "feedbackhub:$IMAGE_TAG" "$ECR_REPO_URI:$IMAGE_TAG"
    push_to_ecr "feedbackhub:$LATEST_TAG" "$ECR_REPO_URI:$LATEST_TAG"
    
    # Cleanup local images
    cleanup_local_images
    
    print_status "Build and push process completed successfully!"
    print_status "ECR Image URI: $ECR_REPO_URI:$IMAGE_TAG"
    print_status "Latest Image URI: $ECR_REPO_URI:$LATEST_TAG"
}

# Run main function
main "$@"
