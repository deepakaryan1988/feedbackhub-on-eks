# FeedbackHub EKS Infrastructure
# Root Terraform configuration that orchestrates all modules

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }

  # Backend configuration - uncomment and configure for remote state
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "feedbackhub-eks/terraform.tfstate"
  #   region = "us-east-1"
  #   
  #   # DynamoDB table for state locking
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

# Configure the AWS Provider
provider "aws" {
  region = coalesce(var.region, var.aws_region)

  # Common tags applied to all AWS resources
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# Configure Kubernetes provider - depends on cluster readiness
# Temporarily commented out to avoid circular dependency during initial deployment
# data "aws_eks_cluster" "cluster" {
#   name       = local.cluster_name
#   depends_on = [
#     null_resource.cluster_health_check
#   ]
# }

# data "aws_eks_cluster_auth" "cluster" {
#   name       = local.cluster_name
#   depends_on = [
#     null_resource.cluster_health_check
#   ]
# }

# Temporarily commented out to avoid circular dependency during initial deployment
# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
# }

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.cluster.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.cluster.token
#   }
# }

# Local variables for computed values
locals {
  cluster_name = "${var.project_name}-${var.environment}"
  
  # Common tags applied to all resources
  common_tags = merge(var.default_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  })

  # VPC CIDR calculations
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = [for i, az in slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count) : cidrsubnet(local.vpc_cidr, 8, i)]
  public_subnet_cidrs  = [for i, az in slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count) : cidrsubnet(local.vpc_cidr, 8, i + 10)]
  
  # Node group configurations
  node_groups = {
    general = {
      instance_types = var.eks_node_instance_type != null ? [var.eks_node_instance_type] : var.node_group_instance_types
      ami_type       = var.node_group_ami_type
      capacity_type  = var.node_group_capacity_type
      disk_size      = var.node_group_disk_size
      desired_size   = coalesce(var.eks_node_desired_size, var.node_group_desired_size)
      max_size       = coalesce(var.eks_node_max_size, var.node_group_max_size)
      min_size       = coalesce(var.eks_node_min_size, var.node_group_min_size)
      
      k8s_labels = {
        role        = "general"
        environment = var.environment
      }
      
      taints = []
    }
  }
  
  # Add spot instance node group if enabled
  spot_node_group = var.enable_spot_instances ? {
    spot = {
      instance_types = var.spot_instance_types
      capacity_type  = "SPOT"
      disk_size      = var.node_group_disk_size
      desired_size   = var.spot_desired_size
      max_size       = var.spot_max_size
      min_size       = var.spot_min_size
      
      k8s_labels = {
        role        = "spot"
        environment = var.environment
      }
      
      taints = [
        {
          key    = "spot-instance"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  } : {}
  
  # Combine general and spot node groups
  active_node_groups = merge(local.node_groups, local.spot_node_group)
}

# Network Module - VPC, Subnets, NAT Gateway, etc.
module "network" {
  source = "../terraform/network"

  # Basic configuration
  cluster_name = local.cluster_name
  vpc_cidr     = local.vpc_cidr
  
  # Subnet configuration
  private_subnet_cidrs = local.private_subnet_cidrs
  public_subnet_cidrs  = local.public_subnet_cidrs
  
  # NAT Gateway configuration - disabled for no-NAT architecture
  # enable_nat_gateway = false  # Removed variable

  # Tags
  tags = local.common_tags
}

# EKS Cluster Module
module "eks_cluster" {
  source = "../terraform/eks/cluster"

  # Basic cluster configuration
  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version
  create_kms_key  = false  # Use existing KMS resources
  
  # Network configuration - using public subnets for no-NAT architecture
  vpc_id                   = module.network.vpc_id
  private_subnet_ids       = module.network.public_subnet_ids  # Changed to public for no-NAT
  cluster_security_group_id = module.network.cluster_security_group_id
  alb_security_group_id    = module.network.alb_security_group_id
  
  # Security configuration
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  
  # Logging
  cluster_enabled_log_types        = var.cluster_enabled_log_types
  cloudwatch_log_retention_days    = var.cloudwatch_log_retention_days
  
  # Fargate and EFS
  enable_fargate  = var.enable_fargate
  enable_efs_csi  = var.enable_efs_csi
  
  # Access entries
  access_entries = var.access_entries
  
  # Tags
  tags = local.common_tags
  
  depends_on = [module.network]
}

# Node Groups Module
module "node_groups" {
  source = "../terraform/eks/nodegroup"

  # Basic configuration
  cluster_name                         = local.cluster_name
  cluster_version                      = var.cluster_version
  cluster_endpoint                     = module.eks_cluster.cluster_endpoint
  cluster_certificate_authority_data  = module.eks_cluster.cluster_certificate_authority_data
  public_subnet_ids                    = module.network.public_subnet_ids  # Use public subnets for no-NAT
  private_subnet_ids                   = module.network.private_subnet_ids  # Keep for compatibility
  node_security_group_id              = module.network.node_group_security_group_id
  
  # Node group configurations
  node_groups = local.active_node_groups

  # Tags
  tags = local.common_tags
  
  depends_on = [module.eks_cluster]
}

# IRSA Module - IAM Roles for Service Accounts
module "irsa" {
  source = "../terraform/irsa"

  # Basic configuration
  cluster_name      = local.cluster_name
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
  oidc_issuer       = module.eks_cluster.cluster_oidc_issuer_url
  
  # Service account roles
  create_alb_controller_role = true
  create_ebs_csi_role       = true
  create_external_dns_role  = var.external_dns_enabled
  
  # Custom IRSA roles
  irsa_roles = merge(
    var.custom_irsa_roles,
    var.enable_monitoring ? {
      prometheus = {
        namespace            = var.monitoring_namespace
        service_account_name = "prometheus"
        managed_policy_arns  = ["arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"]
      }
      grafana = {
        namespace            = var.monitoring_namespace
        service_account_name = "grafana"
        managed_policy_arns  = ["arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"]
      }
    } : {},
    var.enable_logging ? {
      loki = {
        namespace            = var.logging_namespace
        service_account_name = "loki"
        managed_policy_arns  = [
          "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
          "arn:aws:iam::aws:policy/AmazonS3FullAccess"
        ]
      }
      promtail = {
        namespace            = var.logging_namespace
        service_account_name = "promtail"
        managed_policy_arns  = ["arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"]
      }
      fluent-bit = {
        namespace            = var.logging_namespace
        service_account_name = "fluent-bit"
        managed_policy_arns  = ["arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"]
      }
    } : {}
  )
  
  # Tags
  tags = local.common_tags
  
  depends_on = [module.eks_cluster]
}

# Wait for cluster infrastructure to be fully ready
resource "time_sleep" "wait_for_cluster" {
  create_duration = "60s"
  
  depends_on = [
    module.eks_cluster,
    module.node_groups,
    module.irsa
  ]
}

# Cluster health check and readiness validation
resource "null_resource" "cluster_health_check" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "🔍 Validating EKS cluster readiness..."
      
      # Wait for cluster to be active
      echo "⏳ Waiting for EKS cluster to be active..."
      aws eks --no-cli-pager --region ${data.aws_region.current.name} eks wait cluster-active --name ${local.cluster_name}
      echo "✅ EKS cluster is active"
      
      # Wait for all node groups to be active
      echo "⏳ Waiting for node groups to be active..."
      for nodegroup in $(aws eks list-nodegroups --cluster-name ${local.cluster_name} --region ${data.aws_region.current.name} --query 'nodegroups[]' --output text); do
        echo "  - Waiting for nodegroup: $nodegroup"
        aws eks --no-cli-pager --region ${data.aws_region.current.name} eks wait nodegroup-active --cluster-name ${local.cluster_name} --nodegroup-name $nodegroup
      done
      echo "✅ All node groups are active"
      
      # Update kubeconfig
      echo "🔧 Updating kubeconfig..."
      aws eks --no-cli-pager --region ${data.aws_region.current.name} eks update-kubeconfig --name ${local.cluster_name} --alias ${local.cluster_name}
      
      # Wait for API server to be accessible with retries
      echo "⏳ Waiting for Kubernetes API server to be accessible..."
      max_attempts=30
      attempt=1
      
      while [ $attempt -le $max_attempts ]; do
        if kubectl get nodes --request-timeout=10s > /dev/null 2>&1; then
          echo "✅ Kubernetes API server is accessible!"
          break
        fi
        echo "  - Attempt $attempt/$max_attempts: API server not yet accessible, waiting 10 seconds..."
        sleep 10
        attempt=$((attempt + 1))
      done
      
      if [ $attempt -gt $max_attempts ]; then
        echo "❌ Failed to access Kubernetes API server after $max_attempts attempts"
        exit 1
      fi
      
      # Final verification - get nodes and basic cluster info
      echo "🔍 Final cluster verification:"
      kubectl get nodes -o wide
      kubectl get pods -n kube-system --field-selector=status.phase=Running | grep -E "(coredns|aws-node|kube-proxy)" | wc -l
      echo "🎉 EKS cluster and API server are ready for Kubernetes resource deployment!"
    EOT
  }
  
  depends_on = [
    time_sleep.wait_for_cluster
  ]
  
  triggers = {
    cluster_name      = local.cluster_name
    cluster_endpoint  = module.eks_cluster.cluster_endpoint
    node_groups       = jsonencode(local.active_node_groups)
    timestamp         = timestamp()
  }
}



# ALB Controller Module
module "alb_controller" {
  source = "../terraform/eks/alb-ingress"

  # Basic configuration
  cluster_name = module.eks_cluster.cluster_id
  namespace    = "kube-system"
  vpc_id       = module.network.vpc_id
  
  # IRSA configuration
  role_arn                = module.irsa.alb_controller_role_arn
  service_account_name    = "aws-load-balancer-controller"
  create_service_account  = false  # Created by IRSA module
  
  # Controller configuration
  chart_version = var.alb_controller_chart_version
  replica_count = var.alb_controller_replica_count
  resources     = var.alb_controller_resources
  
  # Feature flags
  enable_shield = var.enable_aws_shield
  enable_waf    = var.enable_aws_waf
  
  # Let Helm chart manage IngressClass and CRDs (eliminates timing issues)
  create_ingress_class              = false  # Helm chart creates with createIngressClassResource: true
  create_ingress_class_params       = false  # Helm chart creates with ingressClassParams.create: true  
  create_target_group_binding_crd   = false  # Helm chart creates required CRDs
  
  # Tags
  tags = local.common_tags
  
  depends_on = [
    null_resource.cluster_health_check
  ]
}

# Monitoring Module - Prometheus, Grafana, Alertmanager
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "../terraform/monitoring"

  # Basic configuration
  namespace        = var.monitoring_namespace
  create_namespace = true
  chart_version    = var.monitoring_chart_version
  
  # IRSA configuration
  prometheus_role_arn = module.irsa.prometheus_role_arn
  grafana_role_arn    = module.irsa.grafana_role_arn
  
  # Grafana configuration
  grafana_admin_password = var.grafana_admin_password
  
  # Storage configuration
  prometheus_storage = {
    volumeClaimTemplate = {
      spec = {
        storageClassName = "gp3-retain"
        accessModes      = ["ReadWriteOnce"]
        resources = {
          requests = {
            storage = var.prometheus_storage_size
          }
        }
      }
    }
  }
  
  grafana_persistence = {
    enabled          = true
    storageClassName = "gp3-retain"
    size             = var.grafana_storage_size
    accessModes      = ["ReadWriteOnce"]
  }
  
  # High availability configuration
  prometheus_replicas    = var.prometheus_replicas
  alertmanager_replicas = var.alertmanager_replicas
  
  # Ingress configuration
  prometheus_ingress = var.prometheus_ingress_enabled ? {
    enabled = true
    hosts = [
      {
        host = var.prometheus_hostname
        paths = [
          {
            path     = "/"
            pathType = "Prefix"
          }
        ]
      }
    ]
    tls = var.enable_tls ? [
      {
        secretName = "prometheus-tls"
        hosts      = [var.prometheus_hostname]
      }
    ] : []
    annotations = var.ingress_annotations
  } : { enabled = false, hosts = [], tls = [], annotations = {} }
  
  grafana_ingress = var.grafana_ingress_enabled ? {
    enabled = true
    hosts = [
      {
        host = var.grafana_hostname
        paths = [
          {
            path     = "/"
            pathType = "Prefix"
          }
        ]
      }
    ]
    tls = var.enable_tls ? [
      {
        secretName = "grafana-tls"
        hosts      = [var.grafana_hostname]
      }
    ] : []
    annotations = var.ingress_annotations
  } : { enabled = false, hosts = [], tls = [], annotations = {} }
  
  # Component configuration
  enable_prometheus         = true
  enable_grafana           = true
  enable_alertmanager      = true
  enable_prometheus_operator = true
  enable_kube_state_metrics = true
  enable_node_exporter     = true
  enable_thanos            = var.enable_thanos
  
  # Tags
  tags = local.common_tags
  
  depends_on = [
    null_resource.cluster_health_check,
    module.alb_controller
  ]
}

# Logging Module - Loki, Promtail, CloudWatch
module "logging" {
  count  = var.enable_logging ? 1 : 0
  source = "../terraform/logging"

  # Basic configuration
  namespace        = var.logging_namespace
  cluster_name     = local.cluster_name
  create_namespace = true
  
  # IRSA configuration
  loki_role_arn     = module.irsa.loki_role_arn
  promtail_role_arn = module.irsa.promtail_role_arn
  fluent_bit_role_arn = module.irsa.fluent_bit_role_arn
  
  # Component configuration
  enable_loki       = true
  enable_promtail   = var.log_collector == "promtail"
  enable_fluent_bit = var.log_collector == "fluent-bit"
  
  # Storage configuration
  loki_persistence = {
    enabled          = true
    storageClassName = "gp3-logging"
    size             = var.loki_storage_size
    accessModes      = ["ReadWriteOnce"]
  }
  
  # CloudWatch configuration
  enable_cloudwatch_logging = var.enable_cloudwatch_logging
  cloudwatch_retention_days = var.cloudwatch_retention_days
  
  # Gateway configuration
  enable_gateway = var.enable_loki_gateway
  gateway_ingress = var.loki_gateway_ingress_enabled ? {
    enabled = true
    hosts = [
      {
        host = var.loki_hostname
        paths = [
          {
            path     = "/"
            pathType = "Prefix"
          }
        ]
      }
    ]
    tls = var.enable_tls ? [
      {
        secretName = "loki-tls"
        hosts      = [var.loki_hostname]
      }
    ] : []
    annotations = var.ingress_annotations
  } : { enabled = false, hosts = [], tls = [], annotations = {} }
  
  # Tags
  tags = local.common_tags
  
  depends_on = [
    null_resource.cluster_health_check,
    module.alb_controller
  ]
}
