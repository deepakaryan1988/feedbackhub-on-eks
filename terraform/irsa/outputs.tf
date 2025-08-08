# Outputs for IRSA Module

# Custom IRSA roles
output "irsa_roles" {
  description = "Map of created IRSA roles"
  value = {
    for k, v in aws_iam_role.irsa : k => {
      name = v.name
      arn  = v.arn
    }
  }
}

# ALB Ingress Controller role
output "alb_controller_role_arn" {
  description = "ARN of the ALB Ingress Controller IRSA role"
  value       = var.create_alb_controller_role ? aws_iam_role.alb_controller[0].arn : null
}

output "alb_controller_role_name" {
  description = "Name of the ALB Ingress Controller IRSA role"
  value       = var.create_alb_controller_role ? aws_iam_role.alb_controller[0].name : null
}

# EBS CSI Driver role
output "ebs_csi_driver_role_arn" {
  description = "ARN of the EBS CSI Driver IRSA role"
  value       = var.create_ebs_csi_role ? aws_iam_role.ebs_csi_driver[0].arn : null
}

output "ebs_csi_driver_role_name" {
  description = "Name of the EBS CSI Driver IRSA role"
  value       = var.create_ebs_csi_role ? aws_iam_role.ebs_csi_driver[0].name : null
}

# Alias for backward compatibility
output "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI Driver IRSA role (alias)"
  value       = var.create_ebs_csi_role ? aws_iam_role.ebs_csi_driver[0].arn : null
}

# External DNS role
output "external_dns_role_arn" {
  description = "ARN of the External DNS IRSA role"
  value       = var.create_external_dns_role ? aws_iam_role.external_dns[0].arn : null
}

output "external_dns_role_name" {
  description = "Name of the External DNS IRSA role"
  value       = var.create_external_dns_role ? aws_iam_role.external_dns[0].name : null
}

# Prometheus role
output "prometheus_role_arn" {
  description = "ARN of the Prometheus IRSA role"
  value       = var.create_prometheus_role ? aws_iam_role.prometheus[0].arn : null
}

output "prometheus_role_name" {
  description = "Name of the Prometheus IRSA role"
  value       = var.create_prometheus_role ? aws_iam_role.prometheus[0].name : null
}

# Grafana role
output "grafana_role_arn" {
  description = "ARN of the Grafana IRSA role"
  value       = var.create_grafana_role ? aws_iam_role.grafana[0].arn : null
}

output "grafana_role_name" {
  description = "Name of the Grafana IRSA role"
  value       = var.create_grafana_role ? aws_iam_role.grafana[0].name : null
}

# Loki role
output "loki_role_arn" {
  description = "ARN of the Loki IRSA role"
  value       = var.create_loki_role ? aws_iam_role.loki[0].arn : null
}

output "loki_role_name" {
  description = "Name of the Loki IRSA role"
  value       = var.create_loki_role ? aws_iam_role.loki[0].name : null
}

# Promtail role
output "promtail_role_arn" {
  description = "ARN of the Promtail IRSA role"
  value       = var.create_promtail_role ? aws_iam_role.promtail[0].arn : null
}

output "promtail_role_name" {
  description = "Name of the Promtail IRSA role"
  value       = var.create_promtail_role ? aws_iam_role.promtail[0].name : null
}

# Fluent Bit role
output "fluent_bit_role_arn" {
  description = "ARN of the Fluent Bit IRSA role"
  value       = var.create_fluent_bit_role ? aws_iam_role.fluent_bit[0].arn : null
}

output "fluent_bit_role_name" {
  description = "Name of the Fluent Bit IRSA role"
  value       = var.create_fluent_bit_role ? aws_iam_role.fluent_bit[0].name : null
}

# OIDC Provider ARN (passthrough from cluster module)
output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = var.oidc_provider_arn
}

# All IRSA role ARNs
output "irsa_role_arns" {
  description = "Map of all IRSA role ARNs"
  value = {
    # Custom roles
    for k, v in aws_iam_role.irsa : k => v.arn
  }
}

# Convenience outputs for Kubernetes service account annotations
output "service_account_annotations" {
  description = "Service account annotations for IRSA roles"
  value = merge(
    # Custom roles
    {
      for k, v in aws_iam_role.irsa : k => {
        "eks.amazonaws.com/role-arn" = v.arn
      }
    },
    # Common roles
    var.create_alb_controller_role ? {
      alb_controller = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller[0].arn
      }
    } : {},
    var.create_ebs_csi_role ? {
      ebs_csi_driver = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_driver[0].arn
      }
    } : {},
    var.create_external_dns_role ? {
      external_dns = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns[0].arn
      }
    } : {},
    var.create_prometheus_role ? {
      prometheus = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.prometheus[0].arn
      }
    } : {},
    var.create_grafana_role ? {
      grafana = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.grafana[0].arn
      }
    } : {},
    var.create_loki_role ? {
      loki = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.loki[0].arn
      }
    } : {},
    var.create_promtail_role ? {
      promtail = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.promtail[0].arn
      }
    } : {},
    var.create_fluent_bit_role ? {
      fluent_bit = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.fluent_bit[0].arn
      }
    } : {}
  )
}

# All role ARNs for reference
output "all_role_arns" {
  description = "List of all IRSA role ARNs created by this module"
  value = compact(concat(
    # Custom roles
    [for k, v in aws_iam_role.irsa : v.arn],
    # Common roles
    [
      var.create_alb_controller_role ? aws_iam_role.alb_controller[0].arn : null,
      var.create_ebs_csi_role ? aws_iam_role.ebs_csi_driver[0].arn : null,
      var.create_external_dns_role ? aws_iam_role.external_dns[0].arn : null,
      var.create_prometheus_role ? aws_iam_role.prometheus[0].arn : null,
      var.create_grafana_role ? aws_iam_role.grafana[0].arn : null,
      var.create_loki_role ? aws_iam_role.loki[0].arn : null,
      var.create_promtail_role ? aws_iam_role.promtail[0].arn : null,
      var.create_fluent_bit_role ? aws_iam_role.fluent_bit[0].arn : null,
    ]
  ))
}
