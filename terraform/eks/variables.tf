variable "project" {
  description = "Project name for resource tagging"
  type        = string
}

variable "env" {
  description = "Environment name for resource tagging"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.30"
}

variable "instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t4g.small"]
}

variable "node_min" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 0
}

variable "node_desired" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 1
}

variable "node_max" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 2
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "deepak"
}