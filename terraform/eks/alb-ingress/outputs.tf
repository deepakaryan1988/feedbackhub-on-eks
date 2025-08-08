# Outputs for AWS Load Balancer Controller Module

output "helm_release" {
  description = "Helm release information"
  value = {
    name      = helm_release.aws_load_balancer_controller.name
    namespace = helm_release.aws_load_balancer_controller.namespace
    version   = helm_release.aws_load_balancer_controller.version
    status    = helm_release.aws_load_balancer_controller.status
  }
}

output "service_account_name" {
  description = "Name of the service account"
  value       = var.service_account_name
}

output "service_account_namespace" {
  description = "Namespace of the service account"
  value       = var.namespace
}

output "service_account_arn" {
  description = "ARN annotation of the service account"
  value       = var.role_arn
}

output "ingress_class_name" {
  description = "Name of the created IngressClass"
  value       = var.create_ingress_class ? var.ingress_class_name : null
}

output "ingress_class_params_name" {
  description = "Name of the created IngressClassParams"
  value       = var.create_ingress_class_params ? var.ingress_class_params_name : null
}

output "controller_image" {
  description = "Docker image used for the controller"
  value       = "${var.image_repository}:${var.image_tag}"
}

output "controller_log_level" {
  description = "Log level configured for the controller"
  value       = var.log_level
}

output "metrics_enabled" {
  description = "Whether metrics are enabled"
  value       = var.enable_metrics
}

output "metrics_endpoint" {
  description = "Metrics endpoint address"
  value       = var.enable_metrics ? var.metrics_bind_addr : null
}

output "features_enabled" {
  description = "Map of enabled features"
  value = {
    shield       = var.enable_shield
    waf          = var.enable_waf
    wafv2        = var.enable_wafv2
    cert_manager = var.enable_cert_manager
  }
}

output "webhook_config" {
  description = "Webhook configuration"
  value = {
    failure_policy = var.webhook_failure_policy
  }
}

output "chart_info" {
  description = "Helm chart information"
  value = {
    chart      = "aws-load-balancer-controller"
    version    = var.chart_version
    repository = "https://aws.github.io/eks-charts"
  }
}
