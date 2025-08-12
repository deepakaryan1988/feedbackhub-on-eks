# Outputs for the IRSA ALB Controller module

output "alb_controller_role_arn" {
  description = "ARN of the created IAM role for ALB Controller"
  value       = aws_iam_role.alb_controller.arn
}

output "service_account_namespace" {
  description = "Namespace of the service account"
  value       = var.service_account_namespace
}

output "service_account_name" {
  description = "Name of the service account"
  value       = var.service_account_name
}
