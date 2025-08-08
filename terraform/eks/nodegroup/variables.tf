# Variables for EKS Node Groups Module

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for node groups (no-NAT architecture)"
  type        = list(string)
}

# Keep private_subnet_ids for backward compatibility during transition
variable "private_subnet_ids" {
  description = "List of private subnet IDs for node groups"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Security group ID for EKS nodes"
  type        = string
}

variable "node_groups" {
  description = "Map of EKS managed node group definitions"
  type = map(object({
    # Instance configuration
    instance_types = list(string)
    ami_type       = optional(string, "AL2_x86_64")
    ami_id         = optional(string, null)
    capacity_type  = optional(string, "ON_DEMAND")
    disk_size      = optional(number, 50)

    # Scaling configuration
    desired_size = number
    max_size     = number
    min_size     = number

    # Update configuration
    max_unavailable_percentage = optional(number, 25)

    # Access configuration
    key_name = optional(string, null)

    # Bootstrap configuration
    bootstrap_extra_args = optional(string, "")

    # Kubernetes labels
    k8s_labels = optional(map(string), {})

    # Taints
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))

  default = {
    main = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      max_size       = 4
      min_size       = 1
    }
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
