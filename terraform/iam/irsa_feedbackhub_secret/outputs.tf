# Outputs for the IRSA FeedbackHub Secret module

output "secret_arn" {
  description = "ARN of the created AWS Secrets Manager secret"
  value       = aws_secretsmanager_secret.mongodb_uri.arn
}

output "role_arn" {
  description = "ARN of the created IAM role for secret access"
  value       = aws_iam_role.feedbackhub_secret.arn
}

output "namespace" {
  description = "Kubernetes namespace where resources are created"
  value       = var.namespace
}

output "service_account_name" {
  description = "Name of the ServiceAccount with IRSA annotation"
  value       = var.service_account
}

output "secret_name" {
  description = "Name of the created AWS Secrets Manager secret"
  value       = aws_secretsmanager_secret.mongodb_uri.name
}
