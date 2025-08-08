# Monitoring Module (Prometheus + Grafana + Alertmanager)

This Terraform module deploys a comprehensive monitoring stack on AWS EKS using the **kube-prometheus-stack** Helm chart. It provides production-grade monitoring, alerting, and visualization capabilities with Prometheus, Grafana, and Alertmanager.

## Features

- 🔥 **Production-ready Prometheus** with persistent storage and HA support
- 📊 **Grafana** with pre-configured dashboards and data sources
- 🚨 **Alertmanager** for intelligent alert routing and silencing
- 📈 **Node Exporter** for comprehensive node metrics
- ⚙️ **Prometheus Operator** for CRD-based configuration
- 🏷️ **Kube-state-metrics** for Kubernetes cluster insights
- ☁️ **Thanos** support for long-term storage (optional)
- 🔐 **IRSA integration** for AWS service authentication
- 💾 **GP3 storage** with configurable size and IOPS
- 🌐 **Ingress support** with TLS termination

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Monitoring Stack                        │
├─────────────────────────────────────────────────────────────┤
│  Prometheus  │  Grafana  │  Alertmanager  │  Node Exporter │
│              │           │                │                │
│  - Metrics   │  - Dashb  │  - Alerts      │  - Node Stats  │
│  - Rules     │  - Graphs │  - Routing     │  - Hardware    │
│  - Storage   │  - Users  │  - Silencing   │  - OS Metrics  │
├─────────────────────────────────────────────────────────────┤
│               Prometheus Operator                          │
│  - ServiceMonitors  - PrometheusRules  - Alertmanagers    │
├─────────────────────────────────────────────────────────────┤
│                    Kubernetes                              │
│  - Persistent Volumes  - Services  - ConfigMaps           │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Configuration

```hcl
module "monitoring" {
  source = "../terraform/monitoring"

  # Basic settings
  namespace         = "monitoring"
  chart_version     = "55.5.0"
  create_namespace  = true

  # IRSA roles (created by irsa module)
  prometheus_role_arn = module.irsa.prometheus_role_arn
  grafana_role_arn    = module.irsa.grafana_role_arn

  # Grafana admin credentials
  grafana_admin_password = "admin-secret-password"

  # Storage configuration
  prometheus_storage = {
    volumeClaimTemplate = {
      spec = {
        storageClassName = "gp3-retain"
        accessModes      = ["ReadWriteOnce"]
        resources = {
          requests = {
            storage = "50Gi"
          }
        }
      }
    }
  }

  # Enable components
  enable_prometheus    = true
  enable_grafana      = true
  enable_alertmanager = true
  enable_thanos       = false

  tags = {
    Environment = "production"
    Project     = "feedbackhub"
  }
}
```

### Production Configuration with Ingress

```hcl
module "monitoring" {
  source = "../terraform/monitoring"

  namespace        = "monitoring"
  chart_version    = "55.5.0"
  create_namespace = true

  # High availability
  prometheus_replicas    = 2
  alertmanager_replicas = 3
  
  # Enhanced storage
  prometheus_storage = {
    volumeClaimTemplate = {
      spec = {
        storageClassName = "gp3-retain"
        accessModes      = ["ReadWriteOnce"]
        resources = {
          requests = {
            storage = "100Gi"
          }
        }
      }
    }
  }

  # Grafana with persistence
  grafana_persistence = {
    enabled          = true
    storageClassName = "gp3-retain"
    size             = "10Gi"
    accessModes      = ["ReadWriteOnce"]
  }

  # Ingress configuration
  prometheus_ingress = {
    enabled = true
    hosts = [
      {
        host = "prometheus.yourdomain.com"
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
        secretName = "prometheus-tls"
        hosts      = ["prometheus.yourdomain.com"]
      }
    ]
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:region:account:certificate/cert-id"
    }
  }

  grafana_ingress = {
    enabled = true
    hosts = [
      {
        host = "grafana.yourdomain.com"
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
        secretName = "grafana-tls"
        hosts      = ["grafana.yourdomain.com"]
      }
    ]
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:region:account:certificate/cert-id"
    }
  }

  tags = {
    Environment = "production"
    Project     = "feedbackhub"
  }
}
```

### Thanos Configuration for Long-term Storage

```hcl
module "monitoring" {
  source = "../terraform/monitoring"

  # ... other configuration ...

  # Enable Thanos for long-term storage
  enable_thanos = true
  
  thanos_config = {
    objectStorageConfig = {
      name = "thanos-storage-secret"
      key  = "objstore.yml"
    }
    baseImage = "quay.io/thanos/thanos"
    version   = "v0.32.5"
  }

  # Prometheus configuration for Thanos
  prometheus_external_labels = {
    cluster = "production-eks"
    region  = "us-east-1"
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
| kubernetes | >= 2.20 |
| helm | >= 2.10 |

## Resources Created

### Kubernetes Resources
- **Namespace**: Monitoring namespace (if `create_namespace = true`)
- **Service Accounts**: Prometheus and Grafana (with IRSA annotations)
- **Storage Class**: GP3 storage class for monitoring workloads
- **Secret**: Grafana admin credentials

### Helm Resources
- **kube-prometheus-stack**: Complete monitoring stack deployment

### Monitoring Components Deployed
- **Prometheus Server**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert routing and management
- **Prometheus Operator**: CRD-based configuration management
- **Node Exporter**: Node-level metrics collection
- **Kube-state-metrics**: Kubernetes cluster metrics
- **Prometheus Rules**: Pre-configured alerting rules

## Default Dashboards

The deployment includes pre-configured Grafana dashboards:

- **Kubernetes Overview**: Cluster-wide resource usage
- **Node Exporter**: Detailed node metrics
- **Prometheus Stats**: Prometheus performance metrics
- **Alertmanager**: Alert management interface
- **Pod Monitoring**: Per-pod resource usage
- **Workload Monitoring**: Deployment, StatefulSet, DaemonSet metrics

## Accessing the Monitoring Stack

### Port Forwarding (Development)

```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80

# Alertmanager
kubectl port-forward -n monitoring svc/alertmanager-kube-prometheus-alertmanager 9093:9093
```

### Ingress (Production)

Configure ingress as shown in the production example above. Access via:
- Prometheus: `https://prometheus.yourdomain.com`
- Grafana: `https://grafana.yourdomain.com`
- Alertmanager: `https://alertmanager.yourdomain.com`

## Storage Configuration

### Storage Classes

The module creates a `gp3-retain` storage class optimized for monitoring workloads:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-retain
provisioner: ebs.csi.aws.com
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
```

### Persistence Configuration

Configure persistent storage for each component:

```hcl
# Prometheus storage
prometheus_storage = {
  volumeClaimTemplate = {
    spec = {
      storageClassName = "gp3-retain"
      accessModes      = ["ReadWriteOnce"]
      resources = {
        requests = {
          storage = "100Gi"  # Adjust based on retention and scrape frequency
        }
      }
    }
  }
}

# Grafana storage
grafana_persistence = {
  enabled          = true
  storageClassName = "gp3-retain"
  size             = "10Gi"
  accessModes      = ["ReadWriteOnce"]
}
```

## Security Features

### IRSA Integration

The module supports IAM Roles for Service Accounts (IRSA) for secure AWS service access:

```hcl
# Service accounts with IRSA annotations
prometheus_role_arn = "arn:aws:iam::account:role/eks-prometheus-role"
grafana_role_arn    = "arn:aws:iam::account:role/eks-grafana-role"
```

### Security Contexts

All containers run with enhanced security:

- **Non-root user**: All processes run as non-root
- **Read-only filesystem**: Root filesystem is read-only
- **Security contexts**: Proper user/group IDs
- **Capabilities**: Minimal Linux capabilities

### Network Policies

Optional network policies can be enabled to restrict pod-to-pod communication:

```hcl
enable_network_policies = true
```

## Alerting Configuration

### Default Alert Rules

The stack includes pre-configured alerting rules:

- **Node alerts**: High CPU, memory, disk usage
- **Kubernetes alerts**: Pod crashes, high restart rates
- **Prometheus alerts**: Scrape failures, rule evaluation errors
- **Application alerts**: Custom application metrics

### Alertmanager Configuration

Configure alert routing in Alertmanager:

```hcl
alertmanager_config = {
  global = {
    smtp_smarthost = "smtp.example.com:587"
    smtp_from      = "alerts@example.com"
  }
  route = {
    group_by       = ["alertname"]
    group_wait     = "10s"
    group_interval = "10s"
    repeat_interval = "1h"
    receiver       = "web.hook"
  }
  receivers = [
    {
      name = "web.hook"
      slack_configs = [
        {
          api_url  = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
          channel  = "#alerts"
          text     = "{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}"
        }
      ]
    }
  ]
}
```

## Monitoring Your Applications

### ServiceMonitor Example

Monitor your applications with ServiceMonitor CRDs:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: feedbackhub-api
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: feedbackhub-api
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### Custom Prometheus Rules

Add custom alerting rules:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: feedbackhub-rules
  namespace: monitoring
spec:
  groups:
  - name: feedbackhub.rules
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High error rate detected"
```

## Troubleshooting

### Common Issues

1. **Storage Issues**
   ```bash
   kubectl get pvc -n monitoring
   kubectl describe pvc <pvc-name> -n monitoring
   ```

2. **Pod Startup Issues**
   ```bash
   kubectl get pods -n monitoring
   kubectl describe pod <pod-name> -n monitoring
   kubectl logs <pod-name> -n monitoring
   ```

3. **Service Account Issues**
   ```bash
   kubectl get serviceaccounts -n monitoring
   kubectl describe serviceaccount <sa-name> -n monitoring
   ```

4. **Helm Issues**
   ```bash
   helm list -n monitoring
   helm status kube-prometheus-stack -n monitoring
   ```

### Health Checks

```bash
# Check all pods are running
kubectl get pods -n monitoring

# Check services
kubectl get services -n monitoring

# Check storage
kubectl get pvc -n monitoring

# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets
```

## Resource Planning

### Sizing Guidelines

| Component | CPU Request | Memory Request | Storage |
|-----------|-------------|----------------|---------|
| Prometheus | 500m | 2Gi | 50-100Gi |
| Grafana | 100m | 128Mi | 10Gi |
| Alertmanager | 100m | 128Mi | 2Gi |
| Node Exporter | 100m | 128Mi | - |
| Prometheus Operator | 100m | 128Mi | - |

### Retention Policies

```hcl
# Prometheus retention (default: 15 days)
prometheus_retention = "30d"
prometheus_retention_size = "45GB"

# Alertmanager retention (default: 120 hours)
alertmanager_retention = "168h"  # 7 days
```

## Backup and Recovery

### Prometheus Data Backup

```bash
# Create snapshot (if using supported storage)
kubectl exec -n monitoring prometheus-kube-prometheus-prometheus-0 -- \
  promtool tsdb create-blocks-from-rules \
  --output-dir /prometheus \
  --url http://localhost:9090
```

### Grafana Dashboard Backup

```bash
# Export dashboards
kubectl exec -n monitoring deployment/grafana -- \
  grafana-cli admin export-dashboard --homepath=/usr/share/grafana
```

## License

This module is released under the MIT License. See LICENSE file for details.

## Support

For issues and support:
1. Check the troubleshooting section above
2. Review Prometheus, Grafana, and Kubernetes documentation
3. Open an issue in the project repository
