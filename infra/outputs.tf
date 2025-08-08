# Outputs for FeedbackHub EKS Infrastructure

# General Information
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = local.cluster_name
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# Network Information
output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.network.vpc_cidr
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.network.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.network.public_subnet_ids
}



# EKS Cluster Information
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = module.eks_cluster.cluster_version
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks_cluster.cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL"
  value       = module.eks_cluster.cluster_oidc_issuer_url
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks_cluster.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks_cluster.cluster_arn
}

# Node Groups Information
output "node_groups" {
  description = "Node group information"
  value       = module.node_groups.node_groups
}

output "node_security_group_id" {
  description = "Node security group ID"
  value       = module.network.node_group_security_group_id
}

# IRSA Information
output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = module.irsa.oidc_provider_arn
}

output "alb_controller_role_arn" {
  description = "ALB controller IAM role ARN"
  value       = module.irsa.alb_controller_role_arn
}

output "ebs_csi_role_arn" {
  description = "EBS CSI driver IAM role ARN"
  value       = module.irsa.ebs_csi_role_arn
}

output "external_dns_role_arn" {
  description = "External DNS IAM role ARN"
  value       = var.external_dns_enabled ? module.irsa.external_dns_role_arn : null
}

output "irsa_roles" {
  description = "Map of IRSA role ARNs"
  value       = module.irsa.irsa_role_arns
}

# ALB Controller Information
# output "alb_controller_helm_release" {
#   description = "ALB controller Helm release information"
#   value       = module.alb_controller.helm_release
# }

# Monitoring Information
# output "monitoring_enabled" {
#   description = "Whether monitoring is enabled"
#   value       = var.enable_monitoring
# }

# output "monitoring_namespace" {
#   description = "Monitoring namespace"
#   value       = var.enable_monitoring ? var.monitoring_namespace : null
# }

# output "prometheus_helm_release" {
#   description = "Prometheus Helm release information"
#   value       = var.enable_monitoring ? module.monitoring[0].helm_release : null
# }

# output "grafana_admin_credentials" {
#   description = "Grafana admin credentials"
#   value = var.enable_monitoring ? {
#     username = "admin"
#     password = var.grafana_admin_password
#   } : null
#   sensitive = true
# }

# output "monitoring_access_urls" {
#   description = "Access URLs for monitoring components"
#   value       = var.enable_monitoring ? module.monitoring[0].access_urls : null
# }

# output "monitoring_kubectl_commands" {
#   description = "kubectl commands for monitoring access"
#   value       = var.enable_monitoring ? module.monitoring[0].kubectl_commands : null
# }

# Logging Information
# output "logging_enabled" {
#   description = "Whether logging is enabled"
#   value       = var.enable_logging
# }

# output "logging_namespace" {
#   description = "Logging namespace"
#   value       = var.enable_logging ? var.logging_namespace : null
# }

# output "loki_helm_release" {
#   description = "Loki Helm release information"
#   value       = var.enable_logging ? module.logging[0].helm_release : null
# }

# output "logging_access_urls" {
#   description = "Access URLs for logging components"
#   value       = var.enable_logging ? module.logging[0].access_urls : null
# }

# output "logging_kubectl_commands" {
#   description = "kubectl commands for logging access"
#   value       = var.enable_logging ? module.logging[0].kubectl_commands : null
# }

# output "cloudwatch_log_groups" {
#   description = "CloudWatch log groups"
#   value       = var.enable_logging ? module.logging[0].cloudwatch_log_groups : null
# }

# kubectl Configuration
output "kubectl_config" {
  description = "kubectl configuration command"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${local.cluster_name}"
}

# Quick Access Commands
output "access_commands" {
  description = "Quick access commands for the infrastructure"
  value = {
    update_kubeconfig = "aws eks update-kubeconfig --region ${var.aws_region} --name ${local.cluster_name}"
    
    # Monitoring access
    prometheus_port_forward = var.enable_monitoring ? "kubectl port-forward -n ${var.monitoring_namespace} svc/prometheus-kube-prometheus-prometheus 9090:9090" : "Monitoring not enabled"
    grafana_port_forward    = var.enable_monitoring ? "kubectl port-forward -n ${var.monitoring_namespace} svc/grafana 3000:80" : "Monitoring not enabled"
    
    # Logging access
    loki_port_forward = var.enable_logging ? "kubectl port-forward -n ${var.logging_namespace} svc/loki 3100:3100" : "Logging not enabled"
    
    # General cluster info
    get_nodes    = "kubectl get nodes"
    get_pods_all = "kubectl get pods --all-namespaces"
    cluster_info = "kubectl cluster-info"
  }
}

# Summary Information
output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    cluster = {
      name     = local.cluster_name
      version  = var.cluster_version
      endpoint = module.eks_cluster.cluster_endpoint
      region   = var.aws_region
    }
    
    network = {
      vpc_id              = module.network.vpc_id
      vpc_cidr            = module.network.vpc_cidr
      availability_zones  = length(module.network.private_subnet_ids)
      
    }
    
    node_groups = {
      count           = length(local.active_node_groups)
      instance_types  = var.node_group_instance_types
      spot_enabled    = var.enable_spot_instances
    }
    
    components = {
      # alb_controller = true
      # monitoring     = var.enable_monitoring
      # logging        = var.enable_logging
      external_dns   = var.external_dns_enabled
    }
    
    namespaces = {
      kube_system = "kube-system"
      monitoring  = var.enable_monitoring ? var.monitoring_namespace : null
      logging     = var.enable_logging ? var.logging_namespace : null
    }
  }
}

# Cost Optimization Information
output "cost_optimization" {
  description = "Cost optimization recommendations"
  value = {
    spot_instances_enabled = var.enable_spot_instances
    
    storage_optimization = {
      ebs_gp3_enabled = true
      prometheus_storage = var.enable_monitoring ? var.prometheus_storage_size : "N/A"
      grafana_storage    = var.enable_monitoring ? var.grafana_storage_size : "N/A"
      loki_storage      = var.enable_logging ? var.loki_storage_size : "N/A"
    }
    log_retention = {
      cloudwatch_days = var.cloudwatch_log_retention_days
      prometheus_retention = "15d"  # Default from monitoring module
    }
  }
}

# Security Information
output "security_features" {
  description = "Security features enabled"
  value = {
    private_endpoint_enabled = var.cluster_endpoint_private_access
    public_endpoint_enabled  = var.cluster_endpoint_public_access
    public_access_cidrs      = var.cluster_endpoint_public_access_cidrs
    
    irsa_enabled = true
    
    encryption = {
      cluster_secrets = var.enable_cluster_encryption
      node_volumes   = var.enable_node_group_encryption
      ebs_volumes    = true  # EBS CSI driver with encryption
    }
    
    security_groups = {
      cluster_sg = module.eks_cluster.cluster_security_group_id
      node_sg    = module.network.node_group_security_group_id
    }
    
    logging = {
      control_plane_logs = var.cluster_enabled_log_types
      cloudwatch_enabled = var.enable_cloudwatch_logging
      loki_enabled      = var.enable_logging
    }
  }
}
