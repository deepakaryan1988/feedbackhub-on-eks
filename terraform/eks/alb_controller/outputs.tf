# Outputs for the EKS ALB Controller module

output "service_account_name" {
  description = "Name of the created Kubernetes service account"
  value       = kubernetes_service_account.alb_controller.metadata[0].name
}

output "service_account_namespace" {
  description = "Namespace of the created Kubernetes service account"
  value       = kubernetes_service_account.alb_controller.metadata[0].namespace
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.alb_controller.name
}

output "chart_version" {
  description = "Version of the Helm chart that was installed"
  value       = helm_release.alb_controller.version
}
