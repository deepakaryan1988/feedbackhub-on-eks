# Variables for IRSA Module

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for the EKS cluster"
  type        = string
}

variable "oidc_issuer" {
  description = "URL of the OIDC issuer (without https://)"
  type        = string
}

variable "irsa_roles" {
  description = "Map of IRSA roles to create"
  type = map(object({
    # Kubernetes service account details
    namespace            = string
    service_account_name = string

    # IAM configuration
    max_session_duration = optional(number, 3600)

    # Policy attachments
    managed_policy_arns = optional(list(string), [])
    inline_policies     = optional(map(string), {})

    # Additional assume role conditions
    additional_conditions = optional(map(string), {})
  }))
  default = {}
}

variable "create_alb_controller_role" {
  description = "Whether to create IRSA role for ALB Ingress Controller"
  type        = bool
  default     = true
}

variable "create_ebs_csi_role" {
  description = "Whether to create IRSA role for EBS CSI Driver"
  type        = bool
  default     = true
}

variable "create_external_dns_role" {
  description = "Whether to create IRSA role for External DNS"
  type        = bool
  default     = false
}

variable "create_prometheus_role" {
  description = "Whether to create IRSA role for Prometheus"
  type        = bool
  default     = true
}

variable "create_grafana_role" {
  description = "Whether to create IRSA role for Grafana"
  type        = bool
  default     = true
}

variable "create_loki_role" {
  description = "Whether to create IRSA role for Loki"
  type        = bool
  default     = true
}

variable "create_promtail_role" {
  description = "Whether to create IRSA role for Promtail"
  type        = bool
  default     = true
}

variable "create_fluent_bit_role" {
  description = "Whether to create IRSA role for Fluent Bit"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
