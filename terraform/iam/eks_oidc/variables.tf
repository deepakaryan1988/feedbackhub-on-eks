# Input variables for the EKS OIDC Provider module

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_region" {
  description = "AWS region where the EKS cluster is located"
  type        = string
}
