# FeedbackHub on EKS

A production-ready, cloud-native deployment of the FeedbackHub application on Amazon EKS with comprehensive monitoring, logging, and security capabilities.

## 🚀 Overview

This project migrates the FeedbackHub application from AWS ECS to Amazon EKS, providing enhanced scalability, observability, and cloud-native features. The infrastructure is built using modular Terraform configurations with best practices for security, monitoring, and cost optimization.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              FeedbackHub EKS Architecture                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                Application Layer                                │
│  ┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐ │
│  │   Next.js Frontend  │    │     Next.js API     │    │    MongoDB Atlas    │ │
│  │   (React/TypeScript)│    │   (Node.js/Express) │    │   (Managed Service) │ │
│  │                     │    │                     │    │                     │ │
│  │ ✓ Responsive UI     │    │ ✓ REST API          │    │ ✓ Cloud Database    │ │
│  │ ✓ User Management   │    │ ✓ Authentication    │    │ ✓ High Availability │ │
│  │ ✓ Feedback Forms    │    │ ✓ Data Validation   │    │ ✓ Automated Backups │ │
│  └─────────────────────┘    └─────────────────────┘    └─────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────────┤
│                              Kubernetes Platform                               │
│  ┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐ │
│  │     Monitoring      │    │       Logging       │    │      Ingress        │ │
│  │                     │    │                     │    │                     │ │
│  │ ✓ Prometheus        │    │ ✓ Loki              │    │ ✓ ALB Controller    │ │
│  │ ✓ Grafana           │    │ ✓ Promtail          │    │ ✓ TLS Termination   │ │
│  │ ✓ Alertmanager      │    │ ✓ CloudWatch        │    │ ✓ Path-based Routing│ │
│  │ ✓ Node Exporter     │    │ ✓ Fluent Bit        │    │ ✓ Health Checks     │ │
│  └─────────────────────┘    └─────────────────────┘    └─────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                EKS Cluster                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                            Control Plane (Managed)                        │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐ │
│  │   Managed Node      │    │   Spot Instance     │    │      Fargate        │ │
│  │      Groups         │    │    Node Groups      │    │    (Optional)       │ │
│  │                     │    │                     │    │                     │ │
│  │ ✓ Auto Scaling      │    │ ✓ Cost Optimization │    │ ✓ Serverless        │ │
│  │ ✓ Security Patches  │    │ ✓ Mixed Workloads   │    │ ✓ Zero Management   │ │
│  │ ✓ Instance Refresh  │    │ ✓ Fault Tolerance   │    │ ✓ Isolated Compute  │ │
│  └─────────────────────┘    └─────────────────────┘    └─────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────────┤
│                               Network Layer                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                                 VPC                                       │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐ │ │
│  │  │  Public Subnets │    │ Private Subnets │    │   Security & Access    │ │ │
│  │  │                 │    │                 │    │                         │ │ │
│  │  │ ✓ NAT Gateways  │    │ ✓ EKS Nodes     │    │ ✓ Security Groups       │ │ │
│  │  │ ✓ Load Balancers│    │ ✓ Application   │    │ ✓ Network ACLs          │ │ │
│  │  │ ✓ Internet GW   │    │   Workloads     │    │ ✓ IAM Roles (IRSA)      │ │ │
│  │  │ ✓ Bastion Host  │    │ ✓ Databases     │    │ ✓ VPC Flow Logs         │ │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
```

Placeholder diagram: see `docs/screenshots/architecture.png`.

## ✨ Key Features

### 🏗️ **Infrastructure as Code**
- **Modular Terraform** configuration with reusable modules
- **Multi-environment** support (dev, staging, prod)
- **State management** with S3 backend and DynamoDB locking
- **Automated deployments** with CI/CD integration

### 🔐 **Security & Compliance**
- **IAM Roles for Service Accounts (IRSA)** for secure AWS service access
- **Network segmentation** with private subnets for workloads
- **Encryption at rest** for EBS volumes and Kubernetes secrets
- **Security contexts** with non-root containers and read-only filesystems
- **Network policies** for pod-to-pod communication control
- **VPC Flow Logs** for network traffic analysis

### 📊 **Observability & Monitoring**
- **Prometheus** for metrics collection and alerting
- **Grafana** with pre-built dashboards for Kubernetes and applications
- **Alertmanager** for intelligent alert routing and silencing
- **Loki** for centralized log aggregation and analysis
- **CloudWatch** integration for AWS service logs
- **Distributed tracing** ready with OpenTelemetry support

### 💰 **Cost Optimization**
- **Spot instances** for non-critical workloads (up to 90% savings)
- **Cluster autoscaler** for dynamic node scaling
- **GP3 storage** with optimized IOPS and throughput
- **Resource quotas** and limits for efficient resource utilization
- **Development environment** optimizations

### 🚀 **High Availability & Scalability**
- **Multi-AZ deployment** for fault tolerance
- **Horizontal Pod Autoscaler** for application scaling
- **Vertical Pod Autoscaler** for right-sizing (optional)
- **Persistent storage** with automatic backup and recovery
- **Rolling updates** with zero-downtime deployments

## 📁 Project Structure

```
feedbackhub-on-eks/
├── 📝 .github/
│   └── copilot-instructions.md    # GitHub Copilot workflow instructions
├── 🚀 app/                        # Next.js application source code
│   ├── components/                # React components
│   ├── pages/                     # Next.js pages and API routes
│   ├── lib/                       # Utility libraries and database
│   ├── public/                    # Static assets
│   ├── styles/                    # CSS and styling
│   ├── package.json               # Node.js dependencies
│   ├── next.config.js             # Next.js configuration
│   └── tsconfig.json              # TypeScript configuration
├── 🐳 docker/                     # Docker configurations
│   ├── Dockerfile                 # Production container image
│   ├── Dockerfile.dev             # Development container image
│   └── .dockerignore              # Docker ignore patterns
├── ☸️ k8s/                        # Kubernetes manifests
│   └── manifests/                 # Application deployment configs
│       ├── namespace.yaml         # Application namespace
│       ├── configmap.yaml         # Configuration data
│       ├── secret.yaml            # Sensitive configuration
│       ├── deployment.yaml        # Application deployment
│       ├── service.yaml           # Service definition
│       ├── ingress.yaml           # Ingress configuration
│       └── hpa.yaml               # Horizontal Pod Autoscaler
├── 🛠️ scripts/                    # Build and deployment scripts
│   ├── build.sh                   # Application build script
│   ├── deploy.sh                  # Deployment automation
│   ├── health-check.sh            # Health verification
│   └── cleanup.sh                 # Resource cleanup
├── 🏗️ terraform/                  # Infrastructure modules
│   ├── network/                   # VPC, subnets, security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── cluster/                   # EKS cluster configuration
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── nodegroups/               # Managed node groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── irsa/                     # IAM roles for service accounts
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── alb-controller/           # AWS Load Balancer Controller
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── monitoring/               # Prometheus, Grafana, Alertmanager
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── logging/                  # Loki, Promtail, CloudWatch
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
└── 🎯 infra/                     # Root infrastructure orchestration
    ├── main.tf                   # Main Terraform configuration
    ├── variables.tf              # Variable definitions
    ├── outputs.tf                # Output values
    ├── backend-dev.tf            # Local backend (safe for dev)
    ├── backend-prod.tf           # Commented S3 backend (for later)
    ├── dev.tfvars                # Development defaults (no NAT/ALB)
    ├── prod.tfvars               # Production defaults
    └── README.md                 # Infrastructure documentation
```

## 🚀 Quick Start

### Prerequisites

Ensure you have the following tools installed:

- [AWS CLI](https://aws.amazon.com/cli/) v2.x configured with appropriate permissions
- [Terraform](https://www.terraform.io/) >= 1.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for Kubernetes management
- [Helm](https://helm.sh/) >= 3.0 for package management
- [Docker](https://www.docker.com/) for local development and building

### 1. Run in dev mode (cost-aware, no apply)

```bash
# Clone the repository
git clone <your-repo-url>
cd feedbackhub-on-eks/infra

# Initialize and validate
terraform init
terraform validate

# Preview dev changes (no-cost defaults: NAT/ALB/Ingress disabled)
terraform plan -var-file=dev.tfvars
```

### 2. Verify Deployment

```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check monitoring stack
kubectl get pods -n monitoring

# Check logging stack
kubectl get pods -n logging
```

### 3. Access Applications

```bash
# Access Grafana (monitoring)
kubectl port-forward -n monitoring svc/grafana 3000:80
# Visit http://localhost:3000 (admin/your-password)

# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090

# Access Loki (logging)
kubectl port-forward -n logging svc/loki 3100:3100
# Visit http://localhost:3100
```

### 4. Deploy Application

```bash
# Deploy the FeedbackHub application
cd ../k8s
kubectl apply -f manifests/

# Check application status
kubectl get pods -n feedbackhub
kubectl get ingress -n feedbackhub
```

## 🔧 Configuration

### Environment Variables

The infrastructure supports multiple environments through Terraform variable files:

- **Production**: `terraform.tfvars` (full-featured, high availability)
- **Development**: `terraform.tfvars.dev` (cost-optimized, minimal resources)
- **Staging**: Create `terraform.tfvars.staging` for testing

### Key Configuration Options

| Category | Variable | Description | Default |
|----------|----------|-------------|---------|
| **General** | `aws_region` | AWS region for deployment | `us-east-1` |
| | `environment` | Environment name | `prod` |
| **Cluster** | `cluster_version` | EKS version | `1.29` |
| | `node_group_instance_types` | EC2 instance types | `["t3.medium"]` |
| **Cost** | `enable_spot_instances` | Enable spot instances | `false` |
| | `single_nat_gateway` | Use single NAT gateway | `false` |
| **Monitoring** | `enable_monitoring` | Enable Prometheus/Grafana | `true` |
| | `prometheus_storage_size` | Prometheus storage | `50Gi` |
| **Logging** | `enable_logging` | Enable Loki/Promtail | `true` |
| | `log_collector` | Log collector type | `promtail` |

## 📊 Monitoring & Observability

### Grafana Dashboards

The monitoring stack includes pre-configured dashboards:

1. **Kubernetes Cluster Overview** - Cluster-wide metrics and health
2. **Node Exporter Full** - Detailed node-level metrics
3. **Pod Monitoring** - Per-pod resource usage and performance
4. **Application Performance** - Custom application metrics
5. **Cost Monitoring** - Resource usage and cost optimization

### Prometheus Metrics

Key metrics collected:

- **Infrastructure**: CPU, memory, disk, network
- **Kubernetes**: Pod status, resource usage, events
- **Application**: Custom business metrics, request rates, error rates
- **Cost**: Resource consumption, spot instance savings

### Log Analysis

**Loki** provides centralized logging with:

- **Structured logs** from all applications
- **Kubernetes events** and pod logs
- **System logs** from nodes
- **AWS service logs** via CloudWatch

### Alerting

**Alertmanager** provides intelligent alerting:

- **Critical alerts**: Node failures, pod crashes
- **Warning alerts**: High resource usage, slow response times
- **Custom alerts**: Business logic failures, SLA violations

## 🔒 Security

### Defense in Depth

1. **Network Security**
   - Private subnets for all workloads
   - Security groups with minimal required access
   - Network policies for pod-to-pod communication
   - VPC Flow Logs for traffic analysis

2. **Identity & Access Management**
   - IAM Roles for Service Accounts (IRSA)
   - Least privilege access principles
   - Regular access reviews and rotation

3. **Container Security**
   - Non-root containers
   - Read-only root filesystems
   - Security contexts and capabilities
   - Image vulnerability scanning

4. **Data Protection**
   - Encryption at rest for all storage
   - TLS encryption in transit
   - Secrets management with Kubernetes secrets
   - Regular backup and recovery testing

### Compliance

The infrastructure is designed to meet common compliance requirements:

- **SOC 2** - Security monitoring and logging
- **PCI DSS** - Network segmentation and access controls
- **GDPR** - Data encryption and audit trails
- **HIPAA** - Encryption and access logging (with additional configs)

## 💰 Cost Optimization

### Development Environment Savings

The development configuration provides significant cost savings:

| Resource | Production | Development | Savings |
|----------|------------|-------------|---------|
| **Instances** | t3.medium | t3.small | ~50% |
| **NAT Gateway** | Multi-AZ | Single | ~67% |
| **Storage** | 50Gi | 10Gi | ~80% |
| **Monitoring** | Full stack | Minimal | ~60% |
| **Logging** | CloudWatch + Loki | Loki only | ~40% |

### Production Optimizations

- **Spot instances** for batch workloads (90% savings)
- **GP3 storage** with optimized IOPS
- **Resource quotas** to prevent over-provisioning
- **Cluster autoscaler** for dynamic scaling
- **Right-sizing** with Vertical Pod Autoscaler

### Cost Monitoring

Set up cost monitoring and alerts:

```bash
# Enable cost allocation tags
aws ce put-dimension-key --dimension-key Project
aws ce put-dimension-key --dimension-key Environment

# Create cost budget
aws budgets create-budget \
  --account-id 123456789012 \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

## 🔄 CI/CD Integration

### GitHub Actions Workflow

```yaml
name: Deploy FeedbackHub
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: '18'
    - run: npm ci
      working-directory: ./app
    - run: npm test
      working-directory: ./app

  infrastructure:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v4
    - uses: hashicorp/setup-terraform@v3
    - name: Deploy Infrastructure
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      run: |
        cd infra
        terraform init
        terraform plan
        terraform apply -auto-approve

  deploy:
    needs: infrastructure
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Deploy Application
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      run: |
        aws eks update-kubeconfig --name feedbackhub-prod
        kubectl apply -f k8s/manifests/
```

### GitLab CI/CD

```yaml
stages:
  - test
  - infrastructure
  - deploy

test:
  stage: test
  image: node:18
  script:
    - cd app
    - npm ci
    - npm test

infrastructure:
  stage: infrastructure
  image: hashicorp/terraform:latest
  script:
    - cd infra
    - terraform init
    - terraform plan
    - terraform apply -auto-approve
  only:
    - main

deploy:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - aws eks update-kubeconfig --name feedbackhub-prod
    - kubectl apply -f k8s/manifests/
  only:
    - main
```

## 🆘 Troubleshooting

### Common Issues

#### 1. **Cluster Access Issues**

```bash
# Verify AWS credentials
aws sts get-caller-identity --no-cli-pager

# Update kubeconfig
aws eks --no-cli-pager --region us-east-1 update-kubeconfig --name feedbackhub-prod

# Check cluster status
kubectl cluster-info
```

#### 2. **Pod Scheduling Issues**

```bash
# Check node capacity
kubectl describe nodes
kubectl top nodes

# Check resource requests
kubectl describe pod <pod-name>

# Check node taints and tolerations
kubectl get nodes -o yaml | grep -A5 -B5 taints
```

#### 3. **Monitoring Not Working**

```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets

# Check Grafana datasources
kubectl logs -n monitoring deployment/grafana

# Verify service monitors
kubectl get servicemonitor -n monitoring
```

#### 4. **Application Load Balancer Issues**

```bash
# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify IRSA configuration
kubectl describe serviceaccount aws-load-balancer-controller -n kube-system

# Check ingress status
kubectl describe ingress <ingress-name>
```

### Health Check Commands

```bash
# Infrastructure health
terraform plan  # Check for drift
kubectl get componentstatuses
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running

# Application health
kubectl get pods -n feedbackhub
kubectl logs -f deployment/feedbackhub-api -n feedbackhub

# Monitoring health
curl -s http://localhost:9090/-/healthy  # Prometheus
curl -s http://localhost:3000/api/health  # Grafana

# Logging health
curl -s http://localhost:3100/ready  # Loki
```

## 📈 Performance Tuning

### Application Performance

1. **Resource Optimization**
   ```yaml
   resources:
     requests:
       memory: "256Mi"
       cpu: "250m"
     limits:
       memory: "512Mi"
       cpu: "500m"
   ```

2. **Horizontal Pod Autoscaler**
   ```yaml
   apiVersion: autoscaling/v2
   kind: HorizontalPodAutoscaler
   metadata:
     name: feedbackhub-api-hpa
   spec:
     scaleTargetRef:
       apiVersion: apps/v1
       kind: Deployment
       name: feedbackhub-api
     minReplicas: 2
     maxReplicas: 10
     metrics:
     - type: Resource
       resource:
         name: cpu
         target:
           type: Utilization
           averageUtilization: 70
   ```

### Cluster Performance

1. **Node Group Optimization**
   - Use latest generation instances (t3, m5, r5)
   - Enable GP3 storage with optimized IOPS
   - Configure cluster autoscaler for dynamic scaling

2. **Network Performance**
   - Use enhanced networking (SR-IOV)
   - Enable container insights for network monitoring
   - Optimize service mesh configuration

## 🔄 Backup & Recovery

### Infrastructure Backup

```bash
# Export Terraform state
terraform show > terraform-state-backup.json

# Backup cluster configuration
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml

# Export secrets (encrypted)
kubectl get secrets --all-namespaces -o yaml > secrets-backup.yaml.enc
```

### Application Data Backup

```bash
# Volume snapshots
kubectl create volumesnapshot prometheus-backup \
  --namespace monitoring \
  --source-pvc prometheus-storage

# MongoDB Atlas automated backups (configured in Atlas)
# Point-in-time recovery available
```

### Disaster Recovery

1. **Infrastructure Recovery**
   ```bash
   # Redeploy infrastructure
   terraform apply
   
   # Restore cluster configuration
   kubectl apply -f cluster-backup.yaml
   ```

2. **Data Recovery**
   ```bash
   # Restore from volume snapshots
   kubectl create pvc prometheus-storage-restored \
     --from-snapshot prometheus-backup
   
   # MongoDB restore (Atlas)
   # Use Atlas point-in-time recovery or cluster restore
   ```

## 📚 Additional Resources

### Documentation
- [AWS EKS Best Practices](https://docs.aws.amazon.com/eks/latest/best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Prometheus Monitoring](https://prometheus.io/docs/introduction/overview/)
- [Grafana Documentation](https://grafana.com/docs/)

### Learning Resources
- [EKS Workshop](https://www.eksworkshop.com/)
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [Cloud Native Computing Foundation](https://www.cncf.io/)

### Community
- [AWS Containers Roadmap](https://github.com/aws/containers-roadmap)
- [Kubernetes Slack](https://slack.k8s.io/)
- [CNCF Slack](https://slack.cncf.io/)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

For support and questions:

1. 📖 Check the documentation in each module's README
2. 🐛 Search existing [issues](https://github.com/your-org/feedbackhub-on-eks/issues)
3. 💬 Join our [Slack community](https://your-slack-invite-link)
4. ✉️ Contact the DevOps team

---

**🎯 Built with ❤️ for modern cloud-native applications**

*Empowering developers with production-ready infrastructure*
