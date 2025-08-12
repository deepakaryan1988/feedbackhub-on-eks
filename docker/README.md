# FeedbackHub Docker Setup

This directory contains the Docker configuration for FeedbackHub, optimized for both local development and ECR deployment on AWS.

## 🏗️ Architecture Overview

- **Multi-stage builds** for optimized production images
- **Development environment** with hot reloading support
- **Production-ready** images for ECR and EKS deployment
- **Health checks** for both application and database
- **Security best practices** (non-root users, minimal base images)

## 📁 File Structure

```
docker/
├── Dockerfile              # Production Dockerfile (multi-stage)
├── Dockerfile.dev          # Development Dockerfile
├── Dockerfile.prod         # Production Dockerfile (alternative)
├── docker-compose.yml      # Production compose
├── docker-compose.dev.yml  # Development compose
├── mongo-init.js          # MongoDB initialization script
└── README.md              # This file
```

## 🚀 Quick Start

### Local Development

1. **Start development environment:**
   ```bash
   ./scripts/docker-dev.sh start
   ```

2. **View logs:**
   ```bash
   ./scripts/docker-dev.sh logs
   ```

3. **Stop environment:**
   ```bash
   ./scripts/docker-dev.sh stop
   ```

### Production Build

1. **Build production image:**
   ```bash
   npm run docker:build
   ```

2. **Build for ECR:**
   ```bash
   npm run docker:build:ecr
   ```

## 🔧 Development Environment

### Features
- **Hot reloading** with volume mounting
- **MongoDB** with persistent data
- **Health checks** for both services
- **Optimized volume mounting** to avoid conflicts

### Commands
```bash
./scripts/docker-dev.sh start      # Start development environment
./scripts/docker-dev.sh stop       # Stop development environment
./scripts/docker-dev.sh restart    # Restart services
./scripts/docker-dev.sh logs       # Show app logs
./scripts/docker-dev.sh mongo-logs # Show MongoDB logs
./scripts/docker-dev.sh shell      # Open shell in app container
./scripts/docker-dev.sh status     # Show service status
./scripts/docker-dev.sh clean      # Clean up everything
./scripts/docker-dev.sh build      # Rebuild development image
```

### Volume Mounting Strategy
- **Source code**: Mounted for hot reloading
- **Configuration files**: Read-only mounting
- **Dependencies**: Excluded to avoid conflicts
- **Build artifacts**: Excluded for performance

## 🏭 Production Environment

### Features
- **Multi-stage builds** for minimal image size
- **Security hardening** (non-root user, read-only filesystem)
- **Health checks** with proper endpoints
- **Optimized for ECR** and EKS deployment

### Build Commands
```bash
# Local production build
npm run docker:build:prod

# ECR-ready build
npm run docker:build:ecr

# Custom tag build
docker build -f docker/Dockerfile -t feedbackhub:custom .
```

## ☁️ ECR Deployment

### Prerequisites
- AWS CLI configured with appropriate credentials
- ECR repository created
- Proper IAM permissions

### Deployment Process

1. **Build and push to ECR:**
   ```bash
   ./scripts/build-and-push.sh
   ```

2. **Environment variables:**
   ```bash
   export ECR_REPOSITORY=feedbackhub
   export AWS_REGION=us-east-1
   export IMAGE_TAG=latest
   ```

3. **Manual deployment:**
   ```bash
   # Build image
   docker build -f docker/Dockerfile -t feedbackhub:latest .
   
   # Tag for ECR
   docker tag feedbackhub:latest $ECR_REPOSITORY.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest
   
   # Push to ECR
   docker push $ECR_REPOSITORY.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest
   ```

## 🔍 Health Checks

### Application Health
- **Endpoint**: `/api/health`
- **Interval**: 30 seconds
- **Timeout**: 3 seconds
- **Retries**: 3

### MongoDB Health
- **Command**: `mongosh --eval "db.adminCommand('ping')"`
- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Retries**: 3

## 🛡️ Security Features

- **Non-root user**: UID/GID 1001
- **Minimal base images**: Alpine Linux
- **Read-only filesystem** where possible
- **No secrets** baked into images
- **Health checks** for security monitoring

## 📊 Performance Optimizations

- **Multi-stage builds** for smaller final images
- **Layer caching** optimization
- **Dependency separation** for better caching
- **Volume mounting** exclusions
- **Build context optimization** with .dockerignore

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
- name: Build and Push to ECR
  run: |
    ./scripts/build-and-push.sh
  env:
    ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}
    AWS_REGION: ${{ secrets.AWS_REGION }}
    IMAGE_TAG: ${{ github.sha }}
```

### Local Development Workflow
1. Make code changes
2. Changes automatically reload (hot reloading)
3. Test functionality
4. Commit and push
5. CI/CD builds and deploys to ECR

## 🐛 Troubleshooting

### Common Issues

1. **Port conflicts:**
   ```bash
   # Check what's using port 3000
   lsof -i :3000
   ```

2. **Volume mounting issues:**
   ```bash
   # Check container logs
   ./scripts/docker-dev.sh logs
   ```

3. **MongoDB connection issues:**
   ```bash
   # Check MongoDB status
   ./scripts/docker-dev.sh mongo-logs
   ```

4. **Build failures:**
   ```bash
   # Clean and rebuild
   ./scripts/docker-dev.sh clean
   ./scripts/docker-dev.sh build
   ```

### Debug Commands
```bash
# Check container status
docker ps -a

# Check container logs
docker logs <container_name>

# Inspect container
docker inspect <container_name>

# Check volume mounts
docker volume ls
```

## 📚 Additional Resources

- [Next.js Docker Documentation](https://nextjs.org/docs/deployment#docker-image)
- [Docker Multi-stage Builds](https://docs.docker.com/develop/dev-best-practices/multistage-build/)
- [AWS ECR Best Practices](https://docs.aws.amazon.com/ecr/latest/userguide/best-practices.html)
- [Docker Security Best Practices](https://docs.docker.com/develop/dev-best-practices/)
