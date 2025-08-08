# Outputs for Monitoring Module

# Helm release information
output "helm_release" {
  description = "Helm release information for kube-prometheus-stack"
  value = {
    name      = helm_release.kube_prometheus_stack.name
    namespace = helm_release.kube_prometheus_stack.namespace
    version   = helm_release.kube_prometheus_stack.version
    status    = helm_release.kube_prometheus_stack.status
  }
}

# Namespace information
output "namespace" {
  description = "Monitoring namespace name"
  value       = var.namespace
}

output "namespace_created" {
  description = "Whether the namespace was created by this module"
  value       = var.create_namespace
}

# Service account information
output "prometheus_service_account" {
  description = "Prometheus service account information"
  value = var.create_prometheus_service_account ? {
    name      = kubernetes_service_account.prometheus[0].metadata[0].name
    namespace = kubernetes_service_account.prometheus[0].metadata[0].namespace
    arn       = var.prometheus_role_arn
  } : null
}

output "grafana_service_account" {
  description = "Grafana service account information"
  value = var.create_grafana_service_account ? {
    name      = kubernetes_service_account.grafana[0].metadata[0].name
    namespace = kubernetes_service_account.grafana[0].metadata[0].namespace
    arn       = var.grafana_role_arn
  } : null
}

# Prometheus configuration
output "prometheus_config" {
  description = "Prometheus configuration details"
  value = {
    enabled                = var.enable_prometheus
    replicas              = var.prometheus_replicas
    retention             = var.prometheus_retention
    retention_size        = var.prometheus_retention_size
    scrape_interval       = var.prometheus_scrape_interval
    evaluation_interval   = var.prometheus_evaluation_interval
    storage_class         = var.prometheus_storage.volumeClaimTemplate.spec.storageClassName
    storage_size          = var.prometheus_storage.volumeClaimTemplate.spec.resources.requests.storage
  }
}

# Grafana configuration
output "grafana_config" {
  description = "Grafana configuration details"
  value = {
    enabled           = var.enable_grafana
    admin_user        = var.grafana_admin_user
    persistence_enabled = var.grafana_persistence.enabled
    storage_class     = var.grafana_persistence.storageClassName
    storage_size      = var.grafana_persistence.size
  }
  sensitive = true
}

# Alertmanager configuration
output "alertmanager_config" {
  description = "Alertmanager configuration details"
  value = {
    enabled       = var.enable_alertmanager
    replicas      = var.alertmanager_replicas
    retention     = var.alertmanager_retention
    storage_class = var.alertmanager_storage.volumeClaimTemplate.spec.storageClassName
    storage_size  = var.alertmanager_storage.volumeClaimTemplate.spec.resources.requests.storage
  }
}

# Component status
output "components_enabled" {
  description = "Status of monitoring components"
  value = {
    prometheus         = var.enable_prometheus
    grafana           = var.enable_grafana
    alertmanager      = var.enable_alertmanager
    prometheus_operator = var.enable_prometheus_operator
    kube_state_metrics = var.enable_kube_state_metrics
    node_exporter     = var.enable_node_exporter
    thanos            = var.enable_thanos
  }
}

# Storage class information
output "storage_class" {
  description = "Storage class created for monitoring"
  value = var.create_storage_class ? {
    name                = kubernetes_storage_class.prometheus_gp3[0].metadata[0].name
    provisioner         = kubernetes_storage_class.prometheus_gp3[0].storage_provisioner
    reclaim_policy      = kubernetes_storage_class.prometheus_gp3[0].reclaim_policy
    volume_binding_mode = kubernetes_storage_class.prometheus_gp3[0].volume_binding_mode
    parameters          = kubernetes_storage_class.prometheus_gp3[0].parameters
  } : null
}

# Access URLs (these would be external URLs if ingress is configured)
output "access_urls" {
  description = "Access URLs for monitoring components"
  value = {
    prometheus = var.prometheus_ingress.enabled ? [
      for host in var.prometheus_ingress.hosts : "https://${host.host}"
    ] : ["Access via kubectl port-forward or ingress configuration"]
    
    grafana = var.grafana_ingress.enabled ? [
      for host in var.grafana_ingress.hosts : "https://${host.host}"
    ] : ["Access via kubectl port-forward or ingress configuration"]
    
    alertmanager = var.alertmanager_ingress.enabled ? [
      for host in var.alertmanager_ingress.hosts : "https://${host.host}"
    ] : ["Access via kubectl port-forward or ingress configuration"]
  }
}

# kubectl commands for easy access
output "kubectl_commands" {
  description = "Useful kubectl commands for accessing monitoring components"
  value = {
    prometheus_port_forward = "kubectl port-forward -n ${var.namespace} svc/prometheus-kube-prometheus-prometheus 9090:9090"
    grafana_port_forward    = "kubectl port-forward -n ${var.namespace} svc/grafana 3000:80"
    alertmanager_port_forward = "kubectl port-forward -n ${var.namespace} svc/alertmanager-kube-prometheus-alertmanager 9093:9093"
    
    prometheus_logs = "kubectl logs -n ${var.namespace} -l app.kubernetes.io/name=prometheus"
    grafana_logs    = "kubectl logs -n ${var.namespace} -l app.kubernetes.io/name=grafana"
    alertmanager_logs = "kubectl logs -n ${var.namespace} -l app.kubernetes.io/name=alertmanager"
    
    get_pods = "kubectl get pods -n ${var.namespace}"
    get_services = "kubectl get services -n ${var.namespace}"
    get_configmaps = "kubectl get configmaps -n ${var.namespace}"
    get_secrets = "kubectl get secrets -n ${var.namespace}"
  }
}

# Chart information
output "chart_info" {
  description = "Helm chart information"
  value = {
    chart      = "kube-prometheus-stack"
    version    = var.chart_version
    repository = "https://prometheus-community.github.io/helm-charts"
  }
}

# Resource information
output "resource_usage" {
  description = "Resource allocation for monitoring components"
  value = {
    prometheus = {
      requests = var.prometheus_resources.requests
      limits   = var.prometheus_resources.limits
    }
    grafana = {
      requests = var.grafana_resources.requests
      limits   = var.grafana_resources.limits
    }
    alertmanager = {
      requests = var.alertmanager_resources.requests
      limits   = var.alertmanager_resources.limits
    }
    prometheus_operator = {
      requests = var.prometheus_operator_resources.requests
      limits   = var.prometheus_operator_resources.limits
    }
    node_exporter = {
      requests = var.node_exporter_resources.requests
      limits   = var.node_exporter_resources.limits
    }
  }
}

# Security context information
output "security_context" {
  description = "Security context configuration for monitoring components"
  value = {
    prometheus_user_id = 65534
    grafana_user_id    = 472
    non_root_containers = true
    read_only_root_filesystem = true
  }
}
