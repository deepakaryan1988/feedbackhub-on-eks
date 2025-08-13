variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_region" {
  description = "AWS region where the EKS cluster is located"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the FeedbackHub app"
  type        = string
  default     = "feedbackhub"
}

variable "service_account" {
  description = "Kubernetes service account name for the FeedbackHub app"
  type        = string
  default     = "feedbackhub-app"
}

variable "image" {
  description = "Docker image for the FeedbackHub app"
  type        = string
}

variable "replicas" {
  description = "Number of replicas for the FeedbackHub deployment"
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Container port for the FeedbackHub app"
  type        = number
  default     = 3000
}

variable "health_path" {
  description = "Health check path for liveness and readiness probes"
  type        = string
  default     = "/api/health"
}
