output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = data.aws_eks_cluster.existing.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = data.aws_eks_cluster.existing.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = data.aws_eks_cluster.existing.endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = data.aws_eks_cluster.existing.version
}

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = data.aws_eks_cluster.existing.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = data.aws_eks_cluster.existing.status
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = data.aws_eks_cluster.existing.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = data.aws_eks_cluster.existing.identity[0].oidc[0].issuer
}

# Simplified outputs for existing cluster mode
output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = null  # Will be populated when cluster module is re-enabled
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = null  # Will be populated when cluster module is re-enabled
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enabled"
  value       = null  # Will be populated when cluster module is re-enabled
}

output "kms_key_id" {
  description = "The globally unique identifier for the KMS key"
  value       = var.create_kms_key ? aws_kms_key.eks[0].key_id : data.aws_kms_key.existing_eks[0].key_id
}

output "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key"
  value       = local.kms_key_arn
}
