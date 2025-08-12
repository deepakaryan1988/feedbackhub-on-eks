# Outputs for the EKS OIDC Provider module

output "oidc_provider_arn" {
  description = "ARN of the created IAM OpenID Connect provider"
  value       = aws_iam_openid_connect_provider.eks_oidc.arn
}

output "oidc_provider_url" {
  description = "URL of the created IAM OpenID Connect provider"
  value       = aws_iam_openid_connect_provider.eks_oidc.url
}
