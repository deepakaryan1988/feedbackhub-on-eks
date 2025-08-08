# Logging Module (Loki + Promtail + CloudWatch)

This Terraform module deploys a comprehensive logging stack on AWS EKS using **Loki** for log aggregation, **Promtail** for log collection, and **CloudWatch** for centralized AWS logging. It provides production-grade log collection, storage, and analysis capabilities.

## Features

- 📋 **Loki** for scalable log aggregation and storage
- 🔄 **Promtail** for Kubernetes log collection (DaemonSet)
- 🌊 **Fluent Bit** support as alternative log collector
- ☁️ **CloudWatch integration** for AWS service logs
- 🔐 **IRSA integration** for secure AWS service access
- 💾 **Persistent storage** with GP3 volumes
- 🌐 **Gateway support** for multi-tenant access
- 📊 **Grafana integration** for log visualization
- 🔍 **LogQL support** for powerful log queries
- 🚨 **Alerting integration** with Prometheus/Alertmanager

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Logging Pipeline                        │
├─────────────────────────────────────────────────────────────┤
│  Log Sources  │  Collectors   │  Aggregation  │  Storage    │
│               │               │               │             │
│  - Pod Logs   │  - Promtail   │  - Loki       │  - PVC      │
│  - App Logs   │  - Fluent Bit │  - Gateway    │  - S3       │
│  - Sys Logs   │               │               │             │
├─────────────────────────────────────────────────────────────┤
│  AWS Services │  CloudWatch   │  Log Groups   │  CloudWatch │
│  - EKS Logs   │  - Log Agent  │  - Streams    │  - Insights │
│  - ALB Logs   │  - Fluent Bit │               │             │
├─────────────────────────────────────────────────────────────┤
│                    Kubernetes                              │
│  - DaemonSets  - Services  - ConfigMaps  - PVCs           │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Configuration

```hcl
module "logging" {
  source = "../terraform/logging"

  # Basic settings
  namespace         = "logging"
  cluster_name      = "my-eks-cluster"
  create_namespace  = true

  # IRSA roles (created by irsa module)
  loki_role_arn     = module.irsa.loki_role_arn
  promtail_role_arn = module.irsa.promtail_role_arn

  # Enable core components
  enable_loki     = true
  enable_promtail = true
  enable_cloudwatch_logging = true

  # Storage configuration
  loki_persistence = {
    enabled          = true
    storageClassName = "gp3-logging"
    size             = "20Gi"
    accessModes      = ["ReadWriteOnce"]
  }

  tags = {
    Environment = "production"
    Project     = "feedbackhub"
  }
}
```

### Production Configuration with Gateway

```hcl
module "logging" {
  source = "../terraform/logging"

  namespace        = "logging"
  cluster_name     = "production-eks"
  create_namespace = true

  # Enhanced storage
  loki_persistence = {
    enabled          = true
    storageClassName = "gp3-logging"
    size             = "100Gi"
    accessModes      = ["ReadWriteOnce"]
  }

  # High availability
  loki_resources = {
    requests = {
      memory = "512Mi"
      cpu    = "200m"
    }
    limits = {
      memory = "1Gi"
      cpu    = "500m"
    }
  }

  # Gateway for multi-tenant access
  enable_gateway = true
  gateway_ingress = {
    enabled = true
    hosts = [
      {
        host = "logs.yourdomain.com"
        paths = [
          {
            path     = "/"
            pathType = "Prefix"
          }
        ]
      }
    ]
    tls = [
      {
        secretName = "logs-tls"
        hosts      = ["logs.yourdomain.com"]
      }
    ]
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:region:account:certificate/cert-id"
    }
  }

  # CloudWatch with extended retention
  cloudwatch_retention_days = 90

  tags = {
    Environment = "production"
    Project     = "feedbackhub"
  }
}
```

### Fluent Bit Configuration (Alternative to Promtail)

```hcl
module "logging" {
  source = "../terraform/logging"

  # ... other configuration ...

  # Use Fluent Bit instead of Promtail
  enable_promtail   = false
  enable_fluent_bit = true

  # Fluent Bit configuration
  fluent_bit_config = {
    service = {
      Flush         = 1
      Log_Level     = "info"
      Daemon        = "off"
      Parsers_File  = "parsers.conf"
      HTTP_Server   = "On"
      HTTP_Listen   = "0.0.0.0"
      HTTP_Port     = 2020
    }
    inputs = [
      {
        Name = "tail"
        Path = "/var/log/containers/*.log"
        Parser = "cri"
        Tag = "kube.*"
        Mem_Buf_Limit = "50MB"
        Skip_Long_Lines = "On"
      }
    ]
    outputs = [
      {
        Name = "loki"
        Match = "*"
        Host = "loki"
        Port = 3100
        Labels = "job=fluent-bit"
        Auto_Kubernetes_Labels = "on"
      },
      {
        Name = "cloudwatch_logs"
        Match = "kube.*"
        Region = "us-east-1"
        Log_Group_Name = "/aws/eks/production-eks/application"
        Log_Stream_Prefix = "fluent-bit-"
        Auto_Create_Group = "true"
      }
    ]
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |
| kubernetes | >= 2.20 |
| helm | >= 2.10 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| kubernetes | >= 2.20 |
| helm | >= 2.10 |

## Resources Created

### Kubernetes Resources
- **Namespace**: Logging namespace (if `create_namespace = true`)
- **Service Accounts**: Loki, Promtail, Fluent Bit (with IRSA annotations)
- **Storage Class**: GP3 storage class for logging workloads

### Helm Resources
- **loki-stack**: Complete logging stack deployment

### AWS Resources
- **CloudWatch Log Groups**: Cluster, application, and dataplane logs
- **CloudWatch Log Streams**: API server, audit, authenticator, controller manager, scheduler

### Logging Components Deployed
- **Loki**: Log aggregation and storage
- **Promtail**: Log collection from Kubernetes pods (DaemonSet)
- **Fluent Bit**: Alternative log collector with CloudWatch support
- **Gateway**: Multi-tenant log access (optional)

## Log Collection

### Promtail (Default)

Promtail runs as a DaemonSet and collects logs from:
- Container logs in `/var/log/containers/`
- Pod logs via Kubernetes API
- Host system logs (optional)

```yaml
# Example log entry
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "info",
  "message": "API request processed",
  "kubernetes": {
    "namespace": "default",
    "pod": "feedbackhub-api-7c8b9d5f6-xyz12",
    "container": "api"
  }
}
```

### Fluent Bit (Alternative)

Fluent Bit provides enhanced filtering and multi-output capabilities:
- Better resource efficiency
- Advanced log parsing
- Multiple output destinations
- CloudWatch native integration

## LogQL Queries

### Basic Queries

```logql
# All logs from a specific namespace
{namespace="default"}

# Logs from a specific app
{app="feedbackhub-api"}

# Error logs only
{namespace="default"} |= "ERROR"

# Logs with specific pattern
{namespace="default"} |~ "user.*login"
```

### Advanced Queries

```logql
# Rate of error logs per minute
rate({namespace="default"} |= "ERROR" [1m])

# Top 10 pods by log volume
topk(10, count by (pod) ({namespace="default"}))

# 99th percentile response time
histogram_quantile(0.99, 
  rate({namespace="default"} | json | duration != "" [5m])
)
```

## Accessing the Logging Stack

### Port Forwarding (Development)

```bash
# Loki
kubectl port-forward -n logging svc/loki 3100:3100

# Promtail metrics
kubectl port-forward -n logging svc/promtail 3101:3101

# Access Loki API
curl -G -s 'http://localhost:3100/loki/api/v1/query' \
  --data-urlencode 'query={job="kubernetes-pods"}'
```

### Ingress (Production)

Configure ingress as shown in the production example above. Access via:
- Loki Gateway: `https://logs.yourdomain.com`
- Direct Loki API: `https://loki.yourdomain.com`

### Grafana Integration

Add Loki as a data source in Grafana:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: monitoring
data:
  datasources.yaml: |
    apiVersion: 1
    datasources:
    - name: Loki
      type: loki
      access: proxy
      url: http://loki.logging.svc.cluster.local:3100
      isDefault: false
```

## Storage Configuration

### Loki Storage

Configure persistent storage for Loki:

```hcl
loki_persistence = {
  enabled          = true
  storageClassName = "gp3-logging"
  size             = "100Gi"      # Adjust based on log volume
  accessModes      = ["ReadWriteOnce"]
}
```

### Storage Sizing Guidelines

| Log Volume/Day | Retention | Storage Size |
|----------------|-----------|--------------|
| 1 GB | 7 days | 10 Gi |
| 5 GB | 7 days | 40 Gi |
| 10 GB | 7 days | 80 Gi |
| 50 GB | 7 days | 400 Gi |

### Object Storage (S3)

For long-term storage, configure Loki with S3:

```hcl
loki_config = {
  # ... other config ...
  schema_config = {
    configs = [
      {
        from         = "2024-01-01"
        store        = "tsdb"
        object_store = "s3"
        schema       = "v12"
        index = {
          prefix = "loki_index_"
          period = "24h"
        }
      }
    ]
  }
  storage_config = {
    aws = {
      s3             = "s3://my-loki-bucket"
      region         = "us-east-1"
      s3forcepathstyle = false
    }
  }
}
```

## CloudWatch Integration

### EKS Control Plane Logs

Enable EKS control plane logging:

```hcl
# In your EKS cluster configuration
enabled_cluster_log_types = [
  "api",
  "audit",
  "authenticator",
  "controllerManager",
  "scheduler"
]
```

### Application Logs

Send application logs to CloudWatch via Fluent Bit:

```hcl
enable_fluent_bit = true
fluent_bit_config = {
  outputs = [
    {
      Name = "cloudwatch_logs"
      Match = "kube.*"
      Region = "us-east-1"
      Log_Group_Name = "/aws/eks/my-cluster/application"
      Log_Stream_Prefix = "app-"
      Auto_Create_Group = "true"
    }
  ]
}
```

## Security Features

### IRSA Integration

The module supports IAM Roles for Service Accounts (IRSA):

```hcl
# Service accounts with IRSA annotations
loki_role_arn     = "arn:aws:iam::account:role/eks-loki-role"
promtail_role_arn = "arn:aws:iam::account:role/eks-promtail-role"
```

### Security Contexts

All containers run with enhanced security:

- **Non-root user**: Loki runs as user 10001
- **Read-only filesystem**: Root filesystem is read-only
- **Minimal capabilities**: Dropped ALL capabilities
- **Security contexts**: Proper user/group IDs

### Network Policies

Optional network policies for pod-to-pod communication:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: loki-network-policy
  namespace: logging
spec:
  podSelector:
    matchLabels:
      app: loki
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 3100
```

## Monitoring and Alerting

### Metrics Collection

Promtail and Fluent Bit expose metrics for Prometheus:

```yaml
# ServiceMonitor for Promtail
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: promtail
  namespace: logging
spec:
  selector:
    matchLabels:
      app: promtail
  endpoints:
  - port: http-metrics
    interval: 30s
    path: /metrics
```

### Log-based Alerts

Create alerts based on log patterns:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: log-alerts
  namespace: logging
spec:
  groups:
  - name: log.rules
    rules:
    - alert: HighErrorRate
      expr: rate(promtail_log_entries_total{level="error"}[5m]) > 0.1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High error rate in logs"
```

## Troubleshooting

### Common Issues

1. **Loki Storage Issues**
   ```bash
   kubectl get pvc -n logging
   kubectl describe pvc loki-storage -n logging
   ```

2. **Promtail Collection Issues**
   ```bash
   kubectl logs -n logging -l app=promtail
   kubectl get ds promtail -n logging
   ```

3. **Log Ingestion Issues**
   ```bash
   # Check Loki targets
   kubectl port-forward -n logging svc/loki 3100:3100
   curl -s http://localhost:3100/metrics | grep promtail
   ```

4. **CloudWatch Issues**
   ```bash
   # Check CloudWatch log groups
   aws logs describe-log-groups --log-group-name-prefix "/aws/eks/"
   ```

### Health Checks

```bash
# Check all pods are running
kubectl get pods -n logging

# Check services
kubectl get services -n logging

# Check Loki health
kubectl port-forward -n logging svc/loki 3100:3100
curl -s http://localhost:3100/ready

# Test log query
curl -G -s 'http://localhost:3100/loki/api/v1/query' \
  --data-urlencode 'query={namespace="default"}' \
  --data-urlencode 'limit=10'
```

## Performance Tuning

### Loki Configuration

```hcl
loki_config = {
  limits_config = {
    ingestion_rate_mb        = 8    # MB/s per stream
    ingestion_burst_size_mb  = 16   # Burst size
    max_concurrent_tail_requests = 20
    max_cache_freshness_per_query = "10m"
  }
  query_range = {
    parallelise_shardable_queries = true
    cache_results = true
  }
}
```

### Resource Allocation

```hcl
# High-volume environment
loki_resources = {
  requests = {
    memory = "1Gi"
    cpu    = "500m"
  }
  limits = {
    memory = "2Gi"
    cpu    = "1000m"
  }
}

promtail_resources = {
  requests = {
    memory = "256Mi"
    cpu    = "200m"
  }
  limits = {
    memory = "512Mi"
    cpu    = "400m"
  }
}
```

## Backup and Recovery

### Loki Data Backup

```bash
# Create snapshot (if using volume snapshots)
kubectl create volumesnapshot loki-backup \
  --namespace logging \
  --volumesnapshotclass csi-aws-vsc \
  --source-pvc loki-storage
```

### Configuration Backup

```bash
# Export configurations
kubectl get configmap -n logging -o yaml > loki-configs.yaml
kubectl get secret -n logging -o yaml > loki-secrets.yaml
```

## License

This module is released under the MIT License. See LICENSE file for details.

## Support

For issues and support:
1. Check the troubleshooting section above
2. Review Loki, Promtail, and Kubernetes documentation
3. Open an issue in the project repository
