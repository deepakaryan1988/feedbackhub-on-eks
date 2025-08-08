# FeedbackHub EKS Infrastructure

This repository contains the complete Terraform infrastructure-as-code for deploying FeedbackHub on Amazon EKS with comprehensive monitoring and logging capabilities.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     FeedbackHub EKS Stack                      │
├─────────────────────────────────────────────────────────────────┤
│  Application Layer                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Next.js API   │  │   Frontend      │  │   MongoDB       │ │
│  │   (Kubernetes)  │  │   (Kubernetes)  │  │   (Atlas)       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  Platform Layer                                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Monitoring    │  │    Logging      │  │   Ingress       │ │
│  │   Prometheus    │  │     Loki        │  │   ALB           │ │
│  │   Grafana       │  │   Promtail      │  │   Controller    │ │
│  │   Alertmanager  │  │   CloudWatch    │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  Kubernetes Layer                                              │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    Amazon EKS                             │ │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  │ │
│  │  │  Node Group   │  │ Spot Instances│  │    Fargate    │  │ │
│  │  │  (General)    │  │  (Optional)   │  │  (Optional)   │  │ │
│  │  └───────────────┘  └───────────────┘  └───────────────┘  │ │
│  └─────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  Network Layer                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                        VPC                                │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │ │
│  │  │   Public    │  │   Private   │  │    Security         │ │ │
│  │  │   Subnets   │  │   Subnets   │  │    Groups           │ │ │
│  │  │             │  │             │  │                     │ │ │
│  │  │ NAT Gateway │  │ EKS Nodes   │  │ IRSA Integration    │ │ │
│  │  │ ALB         │  │ Workloads   │  │ IAM Roles           │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 Features

### Core Infrastructure
- **Amazon EKS** cluster with managed node groups
- **VPC** with public/private subnets across multiple AZs
- **NAT Gateway** for private subnet internet access
- **Security Groups** with least privilege access
- **IAM Roles for Service Accounts (IRSA)** for secure AWS service access

### Kubernetes Platform
- **AWS Load Balancer Controller** for ALB integration
- **EBS CSI Driver** for persistent storage
- **Cluster Autoscaler** for automatic scaling
- **CoreDNS**, **kube-proxy**, **VPC CNI** addons

### Monitoring Stack
- **Prometheus** for metrics collection and storage
- **Grafana** for visualization and dashboards
- **Alertmanager** for alert routing and management
- **Node Exporter** for node-level metrics
- **kube-state-metrics** for Kubernetes cluster insights

### Logging Stack
- **Loki** for log aggregation and storage
- **Promtail** for log collection from Kubernetes pods
- **CloudWatch** integration for AWS service logs
- **Fluent Bit** support as alternative log collector

### Security & Compliance
- **Encryption at rest** for EBS volumes and cluster secrets
- **Network policies** for pod-to-pod communication control
- **Security contexts** with non-root containers
- **IMDSv2** enforcement on EC2 instances
- **VPC Flow Logs** for network traffic analysis

### Cost Optimization
- **Spot instances** support for cost savings
- **GP3 storage** with optimized IOPS and throughput
- **Resource limits** and requests for efficient scheduling
- **Configurable retention** for logs and metrics

## 📁 Project Structure

```
feedbackhub-on-eks/
├── app/                          # Next.js application
├── docker/                       # Docker configurations
├── k8s/                         # Kubernetes manifests
├── scripts/                     # Build and deployment scripts
├── terraform/                   # Terraform modules
│   ├── network/                 # VPC, subnets, security groups
│   ├── cluster/                 # EKS cluster configuration
│   ├── nodegroups/             # Node group management
│   ├── irsa/                   # IAM roles for service accounts
│   ├── alb-controller/         # AWS Load Balancer Controller
│   ├── monitoring/             # Prometheus/Grafana stack
│   └── logging/                # Loki/Promtail stack
└── infra/                      # Root infrastructure orchestration
    ├── main.tf                 # Main Terraform configuration
    ├── variables.tf            # Variable definitions
    ├── outputs.tf              # Output values
    ├── terraform.tfvars.example # Example variables
    ├── terraform.tfvars.dev    # Development environment
    └── README.md              # This file
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0
3. **kubectl** for Kubernetes cluster management
4. **Helm** >= 3.0 for package management

### Deployment

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd feedbackhub-on-eks/infra
   ```

2. **Configure variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan the deployment**
   ```bash
   terraform plan
   ```

5. **Deploy the infrastructure**
   ```bash
   terraform apply
   ```

6. **Configure kubectl**
   ```bash
   aws eks --no-cli-pager --region us-east-1 update-kubeconfig --name feedbackhub-prod
   ```

### Environment-Specific Deployment

#### Development Environment
```bash
terraform apply -var-file="terraform.tfvars.dev"
```

#### Production Environment
```bash
terraform apply -var-file="terraform.tfvars"
```

## 🔧 Configuration

### Core Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for deployment | `us-east-1` | Yes |
| `project_name` | Project name for resource naming | `feedbackhub` | Yes |
| `environment` | Environment (dev/staging/prod) | `prod` | Yes |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` | No |
| `cluster_version` | EKS cluster version | `1.29` | No |

### Node Group Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `node_group_instance_types` | EC2 instance types | `["t3.medium"]` |
| `node_group_min_size` | Minimum nodes | `1` |
| `node_group_max_size` | Maximum nodes | `5` |
| `node_group_desired_size` | Desired nodes | `2` |
| `enable_spot_instances` | Enable spot instances | `false` |

### Monitoring Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `enable_monitoring` | Enable monitoring stack | `true` |
| `prometheus_storage_size` | Prometheus storage | `50Gi` |
| `grafana_storage_size` | Grafana storage | `10Gi` |
| `grafana_admin_password` | Grafana admin password | `admin` |

### Logging Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `enable_logging` | Enable logging stack | `true` |
| `log_collector` | Log collector (promtail/fluent-bit) | `promtail` |
| `loki_storage_size` | Loki storage | `20Gi` |
| `enable_cloudwatch_logging` | Enable CloudWatch | `true` |

## 📊 Monitoring & Observability

### Accessing Grafana

1. **Port Forward (Development)**
   ```bash
   kubectl port-forward -n monitoring svc/grafana 3000:80
   ```
   Access: http://localhost:3000
   - Username: `admin`
   - Password: Set in `grafana_admin_password`

2. **Ingress (Production)**
   Configure `grafana_ingress_enabled = true` and set `grafana_hostname`

### Accessing Prometheus

1. **Port Forward**
   ```bash
   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
   ```
   Access: http://localhost:9090

### Accessing Loki

1. **Port Forward**
   ```bash
   kubectl port-forward -n logging svc/loki 3100:3100
   ```
   Access: http://localhost:3100

### Pre-configured Dashboards

- **Kubernetes Cluster Overview**
- **Node Exporter Full**
- **Pod Monitoring**
- **Application Performance**
- **Infrastructure Costs**

## 📝 Logging

### Log Sources

- **Application logs** from all pods
- **System logs** from nodes
- **Kubernetes events**
- **EKS control plane logs**
- **ALB access logs**

### Log Queries (LogQL Examples)

```logql
# All logs from feedbackhub namespace
{namespace="feedbackhub"}

# Error logs only
{namespace="feedbackhub"} |= "ERROR"

# Logs from specific pod
{pod="feedbackhub-api-abc123"}

# Rate of error logs
rate({namespace="feedbackhub"} |= "ERROR" [5m])
```

## 🔒 Security

### IAM Roles for Service Accounts (IRSA)

The infrastructure creates the following IRSA roles:

- **ALB Controller**: Manages Application Load Balancers
- **EBS CSI Driver**: Manages EBS volume lifecycle
- **External DNS**: Updates Route53 records (optional)
- **Prometheus**: CloudWatch read access for metrics
- **Grafana**: CloudWatch read access for dashboards
- **Loki**: CloudWatch Logs and S3 access
- **Promtail/Fluent Bit**: CloudWatch Logs write access

### Security Best Practices

- ✅ **Private subnets** for all worker nodes
- ✅ **Security groups** with minimal required access
- ✅ **Non-root containers** with read-only filesystems
- ✅ **Network policies** for pod-to-pod communication
- ✅ **Encryption at rest** for storage and secrets
- ✅ **IMDSv2** enforcement
- ✅ **VPC Flow Logs** enabled

## 💰 Cost Optimization

### Development Environment

The `terraform.tfvars.dev` configuration includes:

- **Single NAT Gateway** instead of per-AZ
- **Smaller instance types** (t3.small)
- **Reduced storage** allocations
- **Minimal logging** retention
- **Spot instances** for non-critical workloads
- **Single replicas** for monitoring components

### Production Optimizations

- **GP3 storage** with optimized IOPS
- **Spot instances** for batch workloads
- **Resource limits** to prevent over-provisioning
- **Log retention policies**
- **Cluster autoscaler** for dynamic scaling

### Cost Monitoring

Use the AWS Cost Explorer and set up billing alerts:

```bash
# Tag-based cost allocation
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE Type=TAG,Key=Project
```

## 🛠️ Operations

### Scaling Operations

```bash
# Scale node group
kubectl scale deployment feedbackhub-api --replicas=5

# Update node group size
aws eks update-nodegroup-config --cluster-name feedbackhub-prod \
  --nodegroup-name general --scaling-config minSize=2,maxSize=10,desiredSize=5
```

### Backup Operations

```bash
# Backup persistent volumes
kubectl create volumesnapshot prometheus-backup \
  --namespace monitoring --source-pvc prometheus-storage

# Export configurations
kubectl get configmap,secret --all-namespaces -o yaml > cluster-backup.yaml
```

### Disaster Recovery

```bash
# Export cluster configuration
terraform show > cluster-state-backup.txt

# Backup ETCD (managed by AWS)
# EKS automatically handles etcd backups

# Export resource configurations
kubectl get all --all-namespaces -o yaml > workloads-backup.yaml
```

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy to EKS
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1
    
    - name: Deploy infrastructure
      run: |
        cd infra
        terraform init
        terraform plan
        terraform apply -auto-approve
    
    - name: Deploy application
      run: |
        aws eks update-kubeconfig --name feedbackhub-prod
        kubectl apply -f k8s/
```

## 🆘 Troubleshooting

### Common Issues

1. **Node group creation fails**
   ```bash
   # Check IAM permissions
   aws sts get-caller-identity
   aws iam list-attached-role-policies --role-name NodeInstanceRole
   ```

2. **Pods stuck in Pending**
   ```bash
   # Check node capacity
   kubectl describe nodes
   kubectl top nodes
   
   # Check resource requests
   kubectl describe pod <pod-name>
   ```

3. **ALB not creating**
   ```bash
   # Check ALB controller logs
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   
   # Verify IRSA role
   kubectl describe serviceaccount aws-load-balancer-controller -n kube-system
   ```

4. **Monitoring not working**
   ```bash
   # Check Prometheus targets
   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
   # Visit http://localhost:9090/targets
   
   # Check Grafana datasources
   kubectl logs -n monitoring deployment/grafana
   ```

### Health Checks

```bash
# Cluster health
kubectl get componentstatuses

# Node health
kubectl get nodes -o wide

# Pod health
kubectl get pods --all-namespaces

# Service health
kubectl get services --all-namespaces

# Ingress health
kubectl get ingress --all-namespaces
```

## 📚 Documentation

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

For support and questions:

1. Check the [troubleshooting section](#-troubleshooting)
2. Review AWS and Kubernetes documentation
3. Open an issue in the repository
4. Contact the DevOps team

---

**Built with ❤️ for cloud-native applications**
