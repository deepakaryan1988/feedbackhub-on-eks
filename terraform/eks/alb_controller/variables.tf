# Input variables for the EKS ALB Controller module

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_region" {
  description = "AWS region where the EKS cluster is located"
  type        = string
}

variable "alb_controller_role_arn" {
  description = "ARN of the IAM role for the ALB Controller (from IRSA module)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed"
  type        = string
}

variable "chart_version" {
  description = "Version of the aws-load-balancer-controller Helm chart to install"
  type        = string
  default     = "1.13.4"
}
