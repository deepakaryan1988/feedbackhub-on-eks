# Input variables for the IRSA FeedbackHub Secret module

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

variable "namespace" {
  description = "Kubernetes namespace for the FeedbackHub application"
  type        = string
}

variable "service_account" {
  description = "Name of the ServiceAccount that will access the secret"
  type        = string
}

variable "mongodb_uri" {
  description = "MongoDB connection URI (marked as sensitive)"
  type        = string
  sensitive   = true
}

variable "create_namespace" {
  description = "Whether to create the Kubernetes namespace"
  type        = bool
  default     = true
}
