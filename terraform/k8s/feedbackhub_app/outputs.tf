output "deployment_name" {
  description = "Name of the FeedbackHub deployment"
  value       = kubernetes_deployment.feedbackhub.metadata[0].name
}

output "service_name" {
  description = "Name of the FeedbackHub service"
  value       = kubernetes_service.feedbackhub_svc.metadata[0].name
}

output "namespace" {
  description = "Namespace where the FeedbackHub app is deployed"
  value       = kubernetes_namespace.feedbackhub.metadata[0].name
}

output "service_account_name" {
  description = "Name of the service account used by the FeedbackHub app"
  value       = kubernetes_service_account.feedbackhub_app.metadata[0].name
}
