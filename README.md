# FeedbackHub on EKS

A modern, production-ready feedback collection application built with Next.js 14 and deployed on Amazon EKS with infrastructure as code.

## 🚀 Overview

FeedbackHub is a full-stack web application that enables users to submit and view feedback in real-time. Built with modern web technologies and deployed on Kubernetes, it demonstrates best practices for cloud-native application development and deployment.

**This project represents our strategic migration from AWS ECS to Kubernetes (EKS), showcasing enterprise-grade DevOps practices and cloud architecture evolution.**

### 🗺️ **Project Evolution & Roadmap**

> **From ECS to EKS: A Journey of Cloud-Native Evolution**

This project demonstrates our progression from container orchestration (ECS) to Kubernetes (EKS), building upon our successful [feedbackhub-on-awsform](https://github.com/deepakaryan1988/feedbackhub-on-awsform) project.

#### **📊 Progress Overview**

| Phase | Status | Description | Completion |
|-------|--------|-------------|------------|
| **Phase 1-3** | ✅ **COMPLETED** | AWS + ECS Foundations | 100% |
| **Phase 4-6** | ✅ **COMPLETED** | App Migration & Diversification | 100% |
| **Phase 7** | 🚧 **CURRENT** | EKS Mastery | 75% |
| **Phase 8** | ⏳ **PLANNED** | Observability Stack | 0% |
| **Phase 9** | ⏳ **PLANNED** | Security Hardening | 0% |
| **Phase 10** | ⏳ **PLANNED** | CI/CD & GitOps | 0% |
| **Phase 11** | ⏳ **PLANNED** | Advanced Scaling | 0% |
| **Phase 12** | ⏳ **PLANNED** | MLOps Specialization | 0% |

#### **🎯 Current Focus: Phase 7 - EKS Mastery**

**Completed (75%):**
- ✅ EKS Cluster provisioning via Terraform
- ✅ Node groups and ALB Ingress Controller
- ✅ IRSA implementation and basic deployment
- ✅ MongoDB Atlas integration

**In Progress (25%):**
- 🚧 HTTPS + ACM certificate integration
- 🚧 HPA and Cluster Autoscaler setup
- 🚧 Load testing and performance validation
- 🚧 Cost optimization for multi-environment

**[📋 View Detailed Roadmap](docs/ROADMAP.md)** - Comprehensive phase breakdown and future planning

#### **📊 Visual Progress Indicator**

**Overall Project Progress:** 75%
████████████████████████████████████████

**Phase Breakdown:**
- **Phase 1-6:** ██████████████████████████████████████ **100%**
- **Phase 7:**   ████████████████████████████░░░░░░░░░░ **75%**
- **Phase 8-12:**░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ **0%**

### Key Features

- **Real-time Feedback Collection**: Submit and view feedback with instant updates
- **Modern UI/UX**: Built with Next.js 14, TypeScript, and Tailwind CSS
- **Cloud-Native**: Deployed on Amazon EKS with proper health checks and scaling
- **Infrastructure as Code**: Complete Terraform setup for EKS cluster and networking
- **Containerized**: Multi-stage Docker builds for development and production
- **Observability**: Health endpoints, structured logging, and monitoring ready

## 🏗️ Architecture

### Application Stack

- **Frontend**: Next.js 14 with App Router, TypeScript, Tailwind CSS
- **Backend**: Next.js API Routes with MongoDB integration
- **Database**: MongoDB (Atlas recommended for production)
- **Container Runtime**: Docker with multi-stage builds
- **Orchestration**: Kubernetes on Amazon EKS
- **Infrastructure**: Terraform for EKS, VPC, and IAM

### System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Load Balancer │────│   EKS Cluster   │────│   MongoDB       │
│   (ALB)         │    │   (Kubernetes)  │    │   (Atlas/Local) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         │              ┌─────────────────┐
         └──────────────│   FeedbackHub   │
                        │   (Next.js)     │
                        └─────────────────┘
```

### Infrastructure Components

- **VPC**: Public subnets with Internet Gateway (no NAT gateways for cost optimization)
- **EKS Cluster**: Managed Kubernetes cluster with public endpoint access
- **Node Groups**: Managed node groups with t3.small instances for development
- **ALB Controller**: AWS Load Balancer Controller for ingress management
- **IRSA**: IAM Roles for Service Accounts for secure AWS access

## 📁 Project Structure

```
feedbackhub-on-eks/
├── app/                          # Next.js 14 application
│   ├── api/                     # API routes
│   │   ├── feedback/            # Feedback CRUD operations
│   │   ├── health/              # Health check endpoints
│   │   └── hello/               # Sample endpoint
│   ├── components/              # React components
│   │   ├── feedback/            # Feedback-related components
│   │   ├── layout/              # Layout components
│   │   └── ui/                  # Reusable UI components
│   ├── hooks/                   # Custom React hooks
│   ├── lib/                     # Utility libraries
│   ├── types/                   # TypeScript type definitions
│   └── page.tsx                 # Main application page
├── docker/                      # Containerization
│   ├── Dockerfile               # Production Dockerfile
│   ├── Dockerfile.dev           # Development Dockerfile
│   ├── Dockerfile.prod          # Production-optimized Dockerfile
│   ├── docker-compose.yml       # Production compose
│   └── docker-compose.dev.yml   # Development compose
├── k8s/                         # Kubernetes manifests
│   ├── feedbackhub/             # Application-specific manifests
│   ├── manifests/               # Core application deployment
│   └── local-ingress/           # Local development ingress
├── terraform/                   # Infrastructure as Code
│   ├── eks/                     # EKS cluster configuration
│   ├── iam/                     # IAM roles and policies
│   └── network/                 # VPC and networking
├── docs/                        # Documentation
├── scripts/                     # Utility scripts
└── env.example                  # Environment configuration template
```

## 🛠️ Prerequisites

### Required Tools

- **AWS CLI v2**: Configured with appropriate credentials
- **Terraform >= 1.7**: For infrastructure provisioning
- **kubectl**: For Kubernetes cluster management
- **Docker**: For container builds and local development
- **Node.js 18+**: For local development (if not using Docker)

### AWS Requirements

- AWS account with EKS permissions
- IAM user/role with sufficient privileges for EKS, VPC, and IAM operations
- Region preference (default: us-east-1)

## ⚙️ Configuration

### Environment Setup

1. Copy the environment template:
   ```bash
   cp env.example .env.local
   ```

2. Configure required variables:
   ```bash
   # MongoDB connection (required)
   MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/database
   
   # Environment (development/production)
   NODE_ENV=development
   
   # AWS configuration
   AWS_REGION=us-east-1
   AWS_PROFILE=default
   ```

### MongoDB Configuration

- **Development**: Use local MongoDB via Docker Compose
- **Production**: Use MongoDB Atlas with proper authentication
- **Connection String**: Follow MongoDB Atlas connection string format

## 🚀 Local Development

### Option 1: Docker Compose (Recommended)

**Development Environment (No Auth):**
```bash
docker compose -f docker/docker-compose.dev.yml up -d --build
# Application: http://localhost:3000
# MongoDB: mongodb://localhost:27017/feedbackhub
```

**Production-like Environment (With Auth):**
```bash
docker compose -f docker/docker-compose.yml up -d --build
```

### Option 2: Local Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build
```

## 🐳 Container Builds

### Development Image
```bash
docker build -f docker/Dockerfile.dev -t feedbackhub:dev .
```

### Production Image
```bash
docker build -f docker/Dockerfile.prod -t feedbackhub:prod .
```

### Multi-Architecture Build
```bash
docker buildx build --platform linux/amd64,linux/arm64 -f docker/Dockerfile.prod -t feedbackhub:latest .
```

## ☁️ Infrastructure Deployment

### Prerequisites Check

Ensure you have:
- AWS CLI configured with appropriate credentials
- Terraform installed and in PATH
- kubectl installed

### Deployment Order

The infrastructure must be deployed in the following order due to dependencies:

1. **Network Infrastructure**
   ```bash
   cd terraform/network
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```

2. **EKS Cluster**
   ```bash
   cd ../eks
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```

3. **IAM Configuration**
   ```bash
   # EKS OIDC Provider
   cd ../iam/eks_oidc
   terraform init && terraform apply -auto-approve
   
   # ALB Controller IRSA
   cd ../irsa_alb_controller
   terraform init && terraform apply -auto-approve
   ```

4. **ALB Controller**
   ```bash
   cd ../../eks/alb_controller
   terraform init && terraform apply -auto-approve
   ```

### Cluster Access

```bash
# Configure kubectl for EKS
aws eks update-kubeconfig --name feedbackhub-dev --region us-east-1

# Verify cluster access
kubectl get nodes -o wide
kubectl get namespaces
```

### Environment-Specific Configuration

This project uses `*.auto.tfvars` files for environment-specific variables:

```bash
# Copy template for new environment
cp terraform/network/tfvars.template terraform/network/prod.auto.tfvars

# Edit the file with environment-specific values
# Terraform will automatically load these files
```

## 🚀 Application Deployment

### 1. Create Namespaces

```bash
kubectl apply -f k8s/manifests/namespaces.yaml
```

### 2. Deploy Production Application

**Update the deployment manifest:**
- Replace the image reference with your ECR repository
- Update secrets with your MongoDB credentials

**Create secrets:**
```bash
kubectl -n feedbackhub-production create secret generic feedbackhub-secrets \
  --from-literal=mongodb-uri="<your-mongodb-uri>" \
  --from-literal=mongodb-password="<optional-if-used>"
```

**Deploy:**
```bash
kubectl apply -f k8s/manifests/feedbackhub-deployment.yaml
```

### 3. Deploy Development Sample

```bash
# Sample hello service
kubectl apply -f k8s/feedbackhub/hello.yaml

# Development ingress
kubectl apply -f k8s/feedbackhub/ingress-dev.yaml
```

### 4. Verify Deployment

```bash
# Check application status
kubectl -n feedbackhub-production get pods,svc,ingress

# Check development ingress
kubectl -n dev get ingress

# View application logs
kubectl -n feedbackhub-production logs -l app=feedbackhub
```

## 🔍 Application Endpoints

### Health Checks
- `GET /api/health` - Comprehensive health check with MongoDB status
- `GET /api/health/simple` - Lightweight health check for load balancers

### API Endpoints
- `GET /api/feedback` - Retrieve feedback list (paginated, sorted by creation date)
- `POST /api/feedback` - Submit new feedback (requires name and message)

### Kubernetes Probes
- **Liveness Probe**: `/api/health` on port 3000
- **Readiness Probe**: `/api/health` on port 3000
- **Health Check Path**: `/api/health/simple` for ALB health checks

## 🧹 Cleanup

### Destroy Infrastructure (Reverse Order)

```bash
# ALB Controller
cd terraform/eks/alb_controller && terraform destroy -auto-approve

# IAM (IRSA for ALB Controller)
cd ../../iam/irsa_alb_controller && terraform destroy -auto-approve

# IAM (EKS OIDC Provider)
cd ../eks_oidc && terraform destroy -auto-approve

# EKS Cluster
cd ../../eks && terraform destroy -auto-approve

# Network Infrastructure
cd ../network && terraform destroy -auto-approve
```

### Remove Kubernetes Resources

```bash
# Remove application deployments
kubectl delete -f k8s/manifests/feedbackhub-deployment.yaml

# Remove namespaces
kubectl delete -f k8s/manifests/namespaces.yaml

# Remove development resources
kubectl delete -f k8s/feedbackhub/hello.yaml
kubectl delete -f k8s/feedbackhub/ingress-dev.yaml
```

## 🔧 Troubleshooting

### Common Issues

**MongoDB Connection Errors**
- Verify `MONGODB_URI` environment variable is set
- Check MongoDB Atlas network access and credentials
- Verify MongoDB service is running in local development

**ALB Pending Status**
- Ensure AWS Load Balancer Controller is properly installed
- Verify subnet tags for ALB discovery
- Check ingress events: `kubectl describe ingress -n <namespace>`

**Pods Not Ready**
- Check container logs: `kubectl logs <pod-name> -n <namespace>`
- Verify health endpoint accessibility: `kubectl exec <pod-name> -n <namespace> -- curl /api/health`
- Check resource constraints and node capacity

**Terraform Errors**
- Run `terraform fmt` and `terraform validate` before apply
- Verify AWS credentials and region configuration
- Check for state file conflicts

### Debug Commands

```bash
# Check pod status and events
kubectl get pods -n feedbackhub-production -o wide
kubectl describe pod <pod-name> -n feedbackhub-production

# Check service and ingress
kubectl get svc,ingress -n feedbackhub-production
kubectl describe ingress <ingress-name> -n feedbackhub-production

# Check application logs
kubectl logs -f deployment/feedbackhub -n feedbackhub-production

# Verify health endpoint
kubectl port-forward svc/feedbackhub 3000:3000 -n feedbackhub-production
curl http://localhost:3000/api/health
```

## 📊 Monitoring and Observability

### Health Checks
- Application health via `/api/health` endpoint
- MongoDB connectivity status
- Kubernetes readiness and liveness probes

### Logging
- Structured JSON logging
- Request ID tracking for debugging
- Error logging with context

### Metrics (Future Enhancements)
- Prometheus metrics endpoint
- Custom business metrics
- Kubernetes resource utilization

## 🔒 Security Considerations

### Infrastructure Security
- IAM roles with least privilege access
- IRSA for pod-level AWS permissions
- VPC security groups with minimal required access

### Application Security
- Non-root container execution (UID 1001)
- Read-only filesystem where possible
- Secrets managed via Kubernetes Secrets
- No hardcoded credentials in code or images

### Network Security
- Public subnets with controlled access
- ALB security groups
- EKS cluster security groups

## 📈 Scaling and Performance

### Horizontal Pod Autoscaling
- Ready for HPA implementation
- Resource requests and limits configured
- Metrics server integration ready

### Resource Optimization
- Multi-stage Docker builds
- Alpine base images for smaller footprint
- Next.js standalone output for optimized runtime

### Cost Optimization
- Public subnets only (no NAT gateway costs)
- t3.small instances for development
- Spot instances ready for production workloads

## 🤝 Contributing

### Development Workflow
1. Create feature branch from main
2. Make changes following project conventions
3. Run tests and validation
4. Submit pull request with clear description

### Code Standards
- TypeScript for type safety
- ESLint and Prettier for code formatting
- Conventional commit messages
- Comprehensive testing coverage

### Infrastructure Changes
- Terraform plans must be reviewed
- Infrastructure changes require approval
- State files must not be committed to version control

## 📚 Additional Resources

### Documentation
- [Local Ingress Setup](docs/phase0.5-local-ingress.md)
- [Ingress Debug Guide](docs/ingress-debug-cheatsheet.md)
- [Terraform Module Documentation](terraform/README.md)

### External References
- [Next.js 14 Documentation](https://nextjs.org/docs)
- [Amazon EKS Best Practices](https://docs.aws.amazon.com/eks/latest/userguide/best-practices.html)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review application logs and Kubernetes events
3. Check infrastructure status via Terraform
4. Create an issue in the project repository

---

**Built with ❤️ using modern cloud-native technologies**
