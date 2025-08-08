# AWS Load Balancer Controller Module

This Terraform module deploys the AWS Load Balancer Controller (ALB Ingress Controller) to an Amazon EKS cluster using Helm. The controller provisions Application Load Balancers (ALBs) for Kubernetes Ingress resources and Network Load Balancers (NLBs) for services with the appropriate annotations.

## Features

- **Helm-based Deployment**: Uses official AWS Helm chart for reliable deployment
- **IRSA Integration**: Secure IAM role assumption using service accounts
- **High Availability**: Configurable replica count with anti-affinity rules
- **Security Hardened**: Non-root containers, read-only filesystem, dropped capabilities
- **Comprehensive Configuration**: Support for all major controller features
- **Custom Resource Definitions**: Automatic CRD management
- **IngressClass Management**: Configurable default ingress class

## Usage

### Basic Deployment

```hcl
module "alb_controller" {
  source = "./terraform/alb-controller"

  cluster_name = "my-eks-cluster"
  vpc_id       = "vpc-12345678"
  role_arn     = module.irsa.alb_controller_role_arn

  tags = {
    Environment = "production"
    Project     = "feedbackhub"
  }
}
```

### Advanced Configuration

```hcl
module "alb_controller" {
  source = "./terraform/alb-controller"

  cluster_name = "my-eks-cluster"
  vpc_id       = "vpc-12345678"
  role_arn     = module.irsa.alb_controller_role_arn

  # Helm configuration
  chart_version = "1.6.2"
  namespace     = "kube-system"
  
  # Controller configuration
  replica_count = 2
  log_level     = "info"
  
  # Features
  enable_wafv2       = true
  enable_shield      = true
  enable_cert_manager = true
  
  # Resource limits
  resources = {
    limits = {
      cpu    = "500m"
      memory = "1Gi"
    }
    requests = {
      cpu    = "100m"
      memory = "200Mi"
    }
  }

  # Node scheduling
  node_selector = {
    "kubernetes.io/os" = "linux"
  }
  
  tolerations = [
    {
      key      = "CriticalAddonsOnly"
      operator = "Exists"
    }
  ]

  # Ingress class configuration
  create_ingress_class = true
  ingress_class_name   = "alb"
  ingress_class_annotations = {
    "ingressclass.kubernetes.io/is-default-class" = "true"
  }

  # Additional Helm values
  helm_values = {
    "podDisruptionBudget.maxUnavailable" = "1"
    "priorityClassName"                  = "system-cluster-critical"
  }

  tags = {
    Environment = "production"
    Project     = "feedbackhub"
  }
}
```

## Prerequisites

### IRSA Role
The controller requires an IAM role with appropriate permissions. Use the IRSA module to create this role:

```hcl
module "irsa" {
  source = "./terraform/irsa"
  
  cluster_name              = "my-eks-cluster"
  oidc_provider_arn        = module.cluster.oidc_provider_arn
  oidc_issuer              = module.cluster.oidc_issuer
  create_alb_controller_role = true
}
```

### Helm Provider
Configure the Helm provider to connect to your EKS cluster:

```hcl
provider "helm" {
  kubernetes {
    host                   = module.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", module.cluster.cluster_name]
    }
  }
}
```

## Ingress Configuration

### Basic ALB Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: feedbackhub-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /api/health
spec:
  ingressClassName: alb
  rules:
  - host: feedbackhub.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: feedbackhub-service
            port:
              number: 80
```

### HTTPS with SSL Certificate

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: feedbackhub-ingress-tls
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/healthcheck-path: /api/health
spec:
  ingressClassName: alb
  rules:
  - host: feedbackhub.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: feedbackhub-service
            port:
              number: 80
```

### WAF Integration

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: feedbackhub-ingress-waf
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/wafv2-acl-arn: arn:aws:wafv2:us-east-1:123456789012:regional/webacl/ExampleWebACL/473e64fd-f30b-4765-81a0-62ad96dd167a
spec:
  ingressClassName: alb
  rules:
  - host: feedbackhub.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: feedbackhub-service
            port:
              number: 80
```

## Target Group Binding

For direct target group binding without Ingress:

```yaml
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: feedbackhub-tgb
spec:
  serviceRef:
    name: feedbackhub-service
    port: 80
  targetGroupARN: arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/feedbackhub-tg/1234567890123456
```

## Common Annotations

### Load Balancer Annotations

- `alb.ingress.kubernetes.io/scheme`: `internet-facing` or `internal`
- `alb.ingress.kubernetes.io/target-type`: `ip` or `instance`
- `alb.ingress.kubernetes.io/load-balancer-name`: Custom ALB name
- `alb.ingress.kubernetes.io/group.name`: Group multiple Ingresses to single ALB

### Health Check Annotations

- `alb.ingress.kubernetes.io/healthcheck-path`: Health check path
- `alb.ingress.kubernetes.io/healthcheck-interval-seconds`: Check interval
- `alb.ingress.kubernetes.io/healthcheck-timeout-seconds`: Check timeout
- `alb.ingress.kubernetes.io/healthy-threshold-count`: Healthy threshold
- `alb.ingress.kubernetes.io/unhealthy-threshold-count`: Unhealthy threshold

### SSL/TLS Annotations

- `alb.ingress.kubernetes.io/certificate-arn`: ACM certificate ARN
- `alb.ingress.kubernetes.io/ssl-policy`: SSL policy name
- `alb.ingress.kubernetes.io/listen-ports`: Listener port configuration
- `alb.ingress.kubernetes.io/ssl-redirect`: SSL redirect port

### Security Annotations

- `alb.ingress.kubernetes.io/wafv2-acl-arn`: WAF v2 ACL ARN
- `alb.ingress.kubernetes.io/security-groups`: Security group IDs
- `alb.ingress.kubernetes.io/manage-backend-security-group-rules`: Auto-manage SG rules

## Monitoring and Troubleshooting

### Controller Logs

```bash
# View controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Follow logs in real-time
kubectl logs -n kube-system deployment/aws-load-balancer-controller -f
```

### Metrics

The controller exposes Prometheus metrics on port 8080:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: aws-load-balancer-controller-metrics
  namespace: kube-system
spec:
  ports:
  - name: metrics
    port: 8080
    targetPort: 8080
  selector:
    app.kubernetes.io/name: aws-load-balancer-controller
```

### Common Issues

#### Controller Not Starting
1. Check IRSA role permissions
2. Verify service account annotations
3. Check cluster OIDC provider configuration

#### Ingress Not Creating ALB
1. Verify IngressClass is set correctly
2. Check controller logs for errors
3. Ensure VPC and subnet tags are correct
4. Verify security group configurations

#### Target Registration Issues
1. Check security group rules
2. Verify target type (IP vs instance)
3. Check health check configuration
4. Ensure pods are ready and healthy

### Required VPC Tags

Your VPC and subnets must have specific tags for the controller to discover them:

```bash
# Public subnets (for internet-facing ALBs)
kubernetes.io/role/elb = 1

# Private subnets (for internal ALBs)
kubernetes.io/role/internal-elb = 1

# Cluster identification
kubernetes.io/cluster/<cluster-name> = shared
```

## Outputs

| Name | Description |
|------|-------------|
| `helm_release` | Helm release information |
| `service_account_name` | Service account name |
| `service_account_namespace` | Service account namespace |
| `service_account_arn` | IAM role ARN annotation |
| `ingress_class_name` | Created IngressClass name |
| `controller_image` | Controller Docker image |
| `metrics_enabled` | Whether metrics are enabled |
| `features_enabled` | Map of enabled features |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |
| helm | ~> 2.11 |
| kubernetes | ~> 2.23 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |
| helm | ~> 2.11 |
| kubernetes | ~> 2.23 |

## References

- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Installation Guide](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/deploy/installation/)
- [Ingress Annotations](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/guide/ingress/annotations/)
- [Service Annotations](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/guide/service/annotations/)
- [Troubleshooting Guide](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/guide/troubleshooting/)
