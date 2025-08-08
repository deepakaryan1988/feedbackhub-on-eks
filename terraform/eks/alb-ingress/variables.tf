# Variables for AWS Load Balancer Controller Module

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster is deployed"
  type        = string
}

variable "role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller service account"
  type        = string
}

# Helm configuration
variable "helm_release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "chart_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart"
  type        = string
  default     = "1.6.2"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy the controller"
  type        = string
  default     = "kube-system"
}

# Service Account configuration
variable "create_service_account" {
  description = "Whether to create a service account for the controller"
  type        = bool
  default     = true
}

variable "service_account_name" {
  description = "Name of the service account"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "service_account_annotations" {
  description = "Additional annotations for the service account"
  type        = map(string)
  default     = {}
}

# Pod configuration
variable "replica_count" {
  description = "Number of controller replicas"
  type        = number
  default     = 2
}

variable "image_repository" {
  description = "Docker image repository for the controller"
  type        = string
  default     = "602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-load-balancer-controller"
}

variable "image_tag" {
  description = "Docker image tag for the controller"
  type        = string
  default     = "v2.6.2"
}

variable "resources" {
  description = "Resource limits and requests for the controller pods"
  type = object({
    limits = optional(object({
      cpu    = optional(string, "200m")
      memory = optional(string, "500Mi")
    }), {})
    requests = optional(object({
      cpu    = optional(string, "100m")
      memory = optional(string, "200Mi")
    }), {})
  })
  default = {
    limits = {
      cpu    = "200m"
      memory = "500Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "200Mi"
    }
  }
}

# Node scheduling
variable "node_selector" {
  description = "Node selector for pod assignment"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for pod assignment"
  type = list(object({
    key      = optional(string)
    operator = optional(string)
    value    = optional(string)
    effect   = optional(string)
  }))
  default = []
}

variable "affinity" {
  description = "Affinity rules for pod assignment"
  type        = any
  default     = {}
}

# Feature configuration
variable "enable_shield" {
  description = "Enable AWS Shield integration"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Enable AWS WAF integration"
  type        = bool
  default     = false
}

variable "enable_wafv2" {
  description = "Enable AWS WAFv2 integration"
  type        = bool
  default     = true
}

variable "enable_cert_manager" {
  description = "Enable cert-manager integration"
  type        = bool
  default     = false
}

# Ingress class configuration
variable "create_ingress_class" {
  description = "Whether to create the default IngressClass"
  type        = bool
  default     = true
}

variable "ingress_class_name" {
  description = "Name of the IngressClass"
  type        = string
  default     = "alb"
}

variable "ingress_class_annotations" {
  description = "Annotations for the IngressClass"
  type        = map(string)
  default = {
    "ingressclass.kubernetes.io/is-default-class" = "true"
  }
}

variable "create_ingress_class_params" {
  description = "Whether to create IngressClassParams"
  type        = bool
  default     = false
}

variable "ingress_class_params_name" {
  description = "Name of the IngressClassParams"
  type        = string
  default     = "alb-ingress-class-params"
}

variable "ingress_class_params_spec" {
  description = "Spec for IngressClassParams"
  type        = any
  default     = {}
}

# Webhook configuration
variable "webhook_failure_policy" {
  description = "Webhook failure policy (Fail or Ignore)"
  type        = string
  default     = "Fail"
  validation {
    condition     = contains(["Fail", "Ignore"], var.webhook_failure_policy)
    error_message = "Webhook failure policy must be either 'Fail' or 'Ignore'."
  }
}

# Logging and monitoring
variable "log_level" {
  description = "Log level for the controller"
  type        = string
  default     = "info"
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be one of: debug, info, warn, error."
  }
}

variable "enable_metrics" {
  description = "Enable Prometheus metrics"
  type        = bool
  default     = true
}

variable "metrics_bind_addr" {
  description = "Address for metrics endpoint"
  type        = string
  default     = ":8080"
}

# Additional configuration
variable "additional_args" {
  description = "Additional command line arguments for the controller"
  type        = list(string)
  default     = []
}

variable "helm_values" {
  description = "Additional Helm values to set"
  type        = map(string)
  default     = {}
}

variable "create_target_group_binding_crd" {
  description = "Whether to create the TargetGroupBinding CRD"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Additional labels for resources"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
