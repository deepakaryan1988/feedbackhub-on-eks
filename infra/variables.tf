# Variables for FeedbackHub EKS Infrastructure

# General Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# Optional alias for region to support dev/prod tfvars templates
variable "region" {
  description = "Alias for aws_region; prefer aws_region if both set"
  type        = string
  default     = null
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "feedbackhub"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "availability_zones_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3
}

variable "default_tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "feedbackhub"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# NAT Gateway variables removed for no-NAT architecture
# This reduces infrastructure complexity and costs for learning environments

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

# EKS Cluster Configuration
variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain log events in CloudWatch"
  type        = number
  default     = 30
}

variable "enable_fargate" {
  description = "Enable Fargate profiles"
  type        = bool
  default     = false
}

variable "enable_efs_csi" {
  description = "Enable EFS CSI driver"
  type        = bool
  default     = false
}

variable "access_entries" {
  description = "Map of access entries to add to the cluster"
  type        = any
  default     = {}
}

variable "create_cluster_kms_key" {
  description = "Create a KMS key for cluster encryption"
  type        = bool
  default     = true
}

variable "enable_cluster_encryption" {
  description = "Enable cluster encryption"
  type        = bool
  default     = true
}

variable "cluster_kms_key_arn" {
  description = "ARN of existing KMS key for cluster encryption (if not creating new)"
  type        = string
  default     = null
}

variable "cluster_addons" {
  description = "Map of cluster addon configurations"
  type        = any
  default = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }
}

# Node Group Configuration
variable "node_group_instance_types" {
  description = "Instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group"
  type        = string
  default     = "AL2_x86_64"
}

variable "node_group_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_group_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 50
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 5
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

# Simplified EKS sizing inputs (optional overrides used by locals)
variable "eks_node_instance_type" {
  description = "EKS node instance type (single-type convenience var)"
  type        = string
  default     = null
}

variable "eks_node_min_size" {
  description = "Minimum nodes (convenience var)"
  type        = number
  default     = null
}

variable "eks_node_desired_size" {
  description = "Desired nodes (convenience var)"
  type        = number
  default     = null
}

variable "eks_node_max_size" {
  description = "Maximum nodes (convenience var)"
  type        = number
  default     = null
}

# Cost/feature toggles (defaults safe for dev)
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway(s). No effect in no-NAT module, reserved for future use"
  type        = bool
  default     = false
}

variable "create_alb" {
  description = "Create AWS Load Balancer (ALB) controller and related resources"
  type        = bool
  default     = false
}

variable "create_ingress" {
  description = "Enable ingress resources across components by default"
  type        = bool
  default     = false
}

variable "enable_bootstrap_user_data" {
  description = "Enable bootstrap user data"
  type        = bool
  default     = false
}

variable "bootstrap_extra_args" {
  description = "Additional arguments for the bootstrap script"
  type        = string
  default     = ""
}

variable "enable_node_group_encryption" {
  description = "Enable node group root volume encryption"
  type        = bool
  default     = true
}

variable "node_group_kms_key_arn" {
  description = "ARN of KMS key for node group encryption"
  type        = string
  default     = null
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for instances"
  type        = bool
  default     = true
}

# Spot Instances Configuration
variable "enable_spot_instances" {
  description = "Enable spot instance node group"
  type        = bool
  default     = false
}

variable "spot_instance_types" {
  description = "Instance types for spot instances"
  type        = list(string)
  default     = ["t3.medium", "t3.large", "t3a.medium", "t3a.large"]
}

variable "spot_min_size" {
  description = "Minimum number of spot instances"
  type        = number
  default     = 0
}

variable "spot_max_size" {
  description = "Maximum number of spot instances"
  type        = number
  default     = 10
}

variable "spot_desired_size" {
  description = "Desired number of spot instances"
  type        = number
  default     = 2
}

# IRSA Configuration
variable "custom_irsa_roles" {
  description = "Map of custom IRSA roles to create"
  type        = any
  default     = {}
}

variable "external_dns_enabled" {
  description = "Enable External DNS"
  type        = bool
  default     = false
}

# ALB Controller Configuration
variable "alb_controller_chart_version" {
  description = "AWS Load Balancer Controller Helm chart version"
  type        = string
  default     = "1.6.2"
}

variable "alb_controller_replica_count" {
  description = "Number of replicas for ALB controller"
  type        = number
  default     = 2
}

variable "alb_controller_resources" {
  description = "Resource requests and limits for ALB controller"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }
}

variable "enable_aws_shield" {
  description = "Enable AWS Shield support"
  type        = bool
  default     = false
}

variable "enable_aws_waf" {
  description = "Enable AWS WAF support"
  type        = bool
  default     = false
}

variable "enable_aws_cognito" {
  description = "Enable AWS Cognito support"
  type        = bool
  default     = false
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus, Grafana, Alertmanager)"
  type        = bool
  default     = true
}

variable "monitoring_namespace" {
  description = "Namespace for monitoring components"
  type        = string
  default     = "monitoring"
}

variable "monitoring_chart_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
  default     = "55.5.0"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "50Gi"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "10Gi"
}

variable "prometheus_replicas" {
  description = "Number of Prometheus replicas"
  type        = number
  default     = 1
}

variable "alertmanager_replicas" {
  description = "Number of Alertmanager replicas"
  type        = number
  default     = 1
}

variable "enable_thanos" {
  description = "Enable Thanos for long-term storage"
  type        = bool
  default     = false
}

# Ingress Configuration
variable "prometheus_ingress_enabled" {
  description = "Enable ingress for Prometheus"
  type        = bool
  default     = false
}

variable "grafana_ingress_enabled" {
  description = "Enable ingress for Grafana"
  type        = bool
  default     = false
}

variable "prometheus_hostname" {
  description = "Hostname for Prometheus ingress"
  type        = string
  default     = "prometheus.local"
}

variable "grafana_hostname" {
  description = "Hostname for Grafana ingress"
  type        = string
  default     = "grafana.local"
}

variable "enable_tls" {
  description = "Enable TLS for ingress"
  type        = bool
  default     = false
}

variable "ingress_annotations" {
  description = "Annotations for ingress"
  type        = map(string)
  default = {
    "kubernetes.io/ingress.class"                = "alb"
    "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
    "alb.ingress.kubernetes.io/target-type"     = "ip"
  }
}

# Logging Configuration
variable "enable_logging" {
  description = "Enable logging stack (Loki, Promtail)"
  type        = bool
  default     = true
}

variable "logging_namespace" {
  description = "Namespace for logging components"
  type        = string
  default     = "logging"
}

variable "log_collector" {
  description = "Log collector to use (promtail or fluent-bit)"
  type        = string
  default     = "promtail"
  validation {
    condition     = contains(["promtail", "fluent-bit"], var.log_collector)
    error_message = "Log collector must be either 'promtail' or 'fluent-bit'."
  }
}

variable "loki_storage_size" {
  description = "Storage size for Loki"
  type        = string
  default     = "20Gi"
}

variable "enable_cloudwatch_logging" {
  description = "Enable CloudWatch logging"
  type        = bool
  default     = true
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "enable_loki_gateway" {
  description = "Enable Loki gateway"
  type        = bool
  default     = false
}

variable "loki_gateway_ingress_enabled" {
  description = "Enable ingress for Loki gateway"
  type        = bool
  default     = false
}

variable "loki_hostname" {
  description = "Hostname for Loki gateway ingress"
  type        = string
  default     = "loki.local"
}
