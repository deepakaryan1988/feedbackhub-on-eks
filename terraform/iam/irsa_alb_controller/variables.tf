# Input variables for the IRSA ALB Controller module

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_region" {
  description = "AWS region where the EKS cluster is located"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the EKS OIDC provider"
  type        = string
}

variable "service_account_namespace" {
  description = "Kubernetes namespace for the aws-load-balancer-controller service account"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Name of the aws-load-balancer-controller service account"
  type        = string
  default     = "aws-load-balancer-controller"
}
