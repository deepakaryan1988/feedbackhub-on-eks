# Outputs for Logging Module

# Helm release information
output "helm_release" {
  description = "Helm release information for Loki stack"
  value = var.enable_loki ? {
    name      = helm_release.loki_stack[0].name
    namespace = helm_release.loki_stack[0].namespace
    version   = helm_release.loki_stack[0].version
    status    = helm_release.loki_stack[0].status
  } : null
}

# Namespace information
output "namespace" {
  description = "Logging namespace name"
  value       = var.namespace
}

output "namespace_created" {
  description = "Whether the namespace was created by this module"
  value       = var.create_namespace
}

# Service account information
output "loki_service_account" {
  description = "Loki service account information"
  value = var.create_loki_service_account ? {
    name      = kubernetes_service_account.loki[0].metadata[0].name
    namespace = kubernetes_service_account.loki[0].metadata[0].namespace
    arn       = var.loki_role_arn
  } : null
}

output "promtail_service_account" {
  description = "Promtail service account information"
  value = var.create_promtail_service_account ? {
    name      = kubernetes_service_account.promtail[0].metadata[0].name
    namespace = kubernetes_service_account.promtail[0].metadata[0].namespace
    arn       = var.promtail_role_arn
  } : null
}

output "fluent_bit_service_account" {
  description = "Fluent Bit service account information"
  value = var.create_fluent_bit_service_account ? {
    name      = kubernetes_service_account.fluent_bit[0].metadata[0].name
    namespace = kubernetes_service_account.fluent_bit[0].metadata[0].namespace
    arn       = var.fluent_bit_role_arn
  } : null
}

# Component configuration
output "loki_config" {
  description = "Loki configuration details"
  value = {
    enabled             = var.enable_loki
    chart_version       = var.loki_chart_version
    persistence_enabled = var.loki_persistence.enabled
    storage_class       = var.loki_persistence.storageClassName
    storage_size        = var.loki_persistence.size
  }
}

output "promtail_config" {
  description = "Promtail configuration details"
  value = {
    enabled         = var.enable_promtail
    log_collection  = "kubernetes-pods"
    scrape_interval = "30s"
  }
}

output "fluent_bit_config" {
  description = "Fluent Bit configuration details"
  value = {
    enabled = var.enable_fluent_bit
    outputs = var.enable_fluent_bit ? ["loki", "cloudwatch"] : []
  }
}

# Component status
output "components_enabled" {
  description = "Status of logging components"
  value = {
    loki               = var.enable_loki
    promtail           = var.enable_promtail
    fluent_bit         = var.enable_fluent_bit
    grafana            = var.enable_grafana_for_loki
    gateway            = var.enable_gateway
    cloudwatch_logging = var.enable_cloudwatch_logging
  }
}

# Storage class information
output "storage_class" {
  description = "Storage class created for logging"
  value = var.create_storage_class ? {
    name                = kubernetes_storage_class.logging_gp3[0].metadata[0].name
    provisioner         = kubernetes_storage_class.logging_gp3[0].storage_provisioner
    reclaim_policy      = kubernetes_storage_class.logging_gp3[0].reclaim_policy
    volume_binding_mode = kubernetes_storage_class.logging_gp3[0].volume_binding_mode
    parameters          = kubernetes_storage_class.logging_gp3[0].parameters
  } : null
}

# CloudWatch log groups
output "cloudwatch_log_groups" {
  description = "CloudWatch log groups created"
  value = var.enable_cloudwatch_logging ? {
    cluster_logs = {
      name              = aws_cloudwatch_log_group.cluster_logs[0].name
      arn               = aws_cloudwatch_log_group.cluster_logs[0].arn
      retention_in_days = aws_cloudwatch_log_group.cluster_logs[0].retention_in_days
    }
    application_logs = {
      name              = aws_cloudwatch_log_group.application_logs[0].name
      arn               = aws_cloudwatch_log_group.application_logs[0].arn
      retention_in_days = aws_cloudwatch_log_group.application_logs[0].retention_in_days
    }
    dataplane_logs = {
      name              = aws_cloudwatch_log_group.dataplane_logs[0].name
      arn               = aws_cloudwatch_log_group.dataplane_logs[0].arn
      retention_in_days = aws_cloudwatch_log_group.dataplane_logs[0].retention_in_days
    }
  } : null
}

# CloudWatch log streams
output "cloudwatch_log_streams" {
  description = "CloudWatch log streams created"
  value = var.enable_cloudwatch_logging ? {
    api_server         = aws_cloudwatch_log_stream.api_server[0].name
    audit              = aws_cloudwatch_log_stream.audit[0].name
    authenticator      = aws_cloudwatch_log_stream.authenticator[0].name
    controller_manager = aws_cloudwatch_log_stream.controllerManager[0].name
    scheduler          = aws_cloudwatch_log_stream.scheduler[0].name
  } : null
}

# Access URLs (these would be external URLs if ingress is configured)
output "access_urls" {
  description = "Access URLs for logging components"
  value = {
    loki = var.loki_ingress.enabled ? [
      for host in var.loki_ingress.hosts : "https://${host.host}"
    ] : ["Access via kubectl port-forward or ingress configuration"]

    gateway = var.gateway_ingress.enabled ? [
      for host in var.gateway_ingress.hosts : "https://${host.host}"
    ] : var.enable_gateway ? ["Access via kubectl port-forward or ingress configuration"] : ["Gateway not enabled"]
  }
}

# kubectl commands for easy access
output "kubectl_commands" {
  description = "Useful kubectl commands for accessing logging components"
  value = {
    loki_port_forward = "kubectl port-forward -n ${var.namespace} svc/loki 3100:3100"
    promtail_logs     = "kubectl logs -n ${var.namespace} -l app.kubernetes.io/name=promtail"
    fluent_bit_logs   = var.enable_fluent_bit ? "kubectl logs -n ${var.namespace} -l app.kubernetes.io/name=fluent-bit" : "Fluent Bit not enabled"

    get_pods       = "kubectl get pods -n ${var.namespace}"
    get_services   = "kubectl get services -n ${var.namespace}"
    get_configmaps = "kubectl get configmaps -n ${var.namespace}"
    get_secrets    = "kubectl get secrets -n ${var.namespace}"
    get_pvc        = "kubectl get pvc -n ${var.namespace}"

    # Log queries
    loki_query_api = "curl -G -s 'http://localhost:3100/loki/api/v1/query' --data-urlencode 'query={job=\"kubernetes-pods\"}'"
    loki_labels    = "curl -s 'http://localhost:3100/loki/api/v1/labels'"
  }
}

# Chart information
output "chart_info" {
  description = "Helm chart information"
  value = {
    chart      = "loki-stack"
    version    = var.loki_chart_version
    repository = "https://grafana.github.io/helm-charts"
  }
}

# Resource information
output "resource_usage" {
  description = "Resource allocation for logging components"
  value = {
    loki = {
      requests = var.loki_resources.requests
      limits   = var.loki_resources.limits
    }
    promtail = var.enable_promtail ? {
      requests = var.promtail_resources.requests
      limits   = var.promtail_resources.limits
    } : null
    fluent_bit = var.enable_fluent_bit ? {
      requests = var.fluent_bit_resources.requests
      limits   = var.fluent_bit_resources.limits
    } : null
    gateway = var.enable_gateway ? {
      requests = var.gateway_resources.requests
      limits   = var.gateway_resources.limits
    } : null
  }
}

# Security context information
output "security_context" {
  description = "Security context configuration for logging components"
  value = {
    loki = {
      user_id           = var.loki_security_context.runAsUser
      group_id          = var.loki_security_context.runAsGroup
      non_root          = var.loki_security_context.runAsNonRoot
      read_only_root_fs = var.loki_security_context.readOnlyRootFilesystem
    }
    promtail = var.enable_promtail ? {
      user_id           = var.promtail_security_context.runAsUser
      group_id          = var.promtail_security_context.runAsGroup
      non_root          = var.promtail_security_context.runAsNonRoot
      read_only_root_fs = var.promtail_security_context.readOnlyRootFilesystem
    } : null
    fluent_bit = var.enable_fluent_bit ? {
      user_id           = var.fluent_bit_security_context.runAsUser
      group_id          = var.fluent_bit_security_context.runAsGroup
      non_root          = var.fluent_bit_security_context.runAsNonRoot
      read_only_root_fs = var.fluent_bit_security_context.readOnlyRootFilesystem
    } : null
  }
}

# Log retention information
output "log_retention" {
  description = "Log retention configuration"
  value = {
    loki_retention = {
      max_age           = var.loki_config.limits_config.reject_old_samples_max_age
      ingestion_rate_mb = var.loki_config.limits_config.ingestion_rate_mb
      burst_size_mb     = var.loki_config.limits_config.ingestion_burst_size_mb
    }
    cloudwatch_retention = var.enable_cloudwatch_logging ? {
      retention_days = var.cloudwatch_retention_days
    } : null
  }
}

# Integration information
output "integration_info" {
  description = "Integration information for other modules"
  value = {
    loki_endpoint               = "http://loki.${var.namespace}.svc.cluster.local:3100"
    promtail_metrics_endpoint   = var.enable_promtail ? "http://promtail.${var.namespace}.svc.cluster.local:3101/metrics" : null
    fluent_bit_metrics_endpoint = var.enable_fluent_bit ? "http://fluent-bit.${var.namespace}.svc.cluster.local:2020/api/v1/metrics/prometheus" : null

    # For Grafana datasource configuration
    grafana_datasource_config = {
      name      = "Loki"
      type      = "loki"
      url       = "http://loki.${var.namespace}.svc.cluster.local:3100"
      access    = "proxy"
      isDefault = false
    }
  }
}
