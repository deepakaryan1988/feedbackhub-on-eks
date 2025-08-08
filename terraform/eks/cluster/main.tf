# EKS Cluster Module using terraform-aws-modules/eks
# This module creates the EKS control plane with IRSA enabled

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Data source for current AWS caller identity
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}

# Data source for existing KMS key (if not creating new one)
data "aws_kms_key" "existing_eks" {
  count = var.create_kms_key ? 0 : 1
  key_id = "alias/eks/${var.cluster_name}"
}

# KMS Key for EKS encryption
# Only create if it doesn't already exist
resource "aws_kms_key" "eks" {
  count = var.create_kms_key ? 1 : 0
  
  description             = "EKS Secret Encryption Key for ${var.cluster_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-eks-kms-key"
  })
}

resource "aws_kms_alias" "eks" {
  count = var.create_kms_key ? 1 : 0
  
  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks[0].key_id
}

# Local value to get the correct KMS key ARN
locals {
  kms_key_arn = var.create_kms_key ? aws_kms_key.eks[0].arn : data.aws_kms_key.existing_eks[0].arn
}

# CloudWatch Log Group for EKS is automatically created by the EKS module
# when cluster_enabled_log_types is configured

# Data source to reference existing EKS cluster instead of creating
data "aws_eks_cluster" "existing" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "existing" {
  name = var.cluster_name
}

# EKS Cluster using terraform-aws-modules/eks - DISABLED during recovery
# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.0"
# 
#   cluster_name                   = var.cluster_name
#   cluster_version                = var.cluster_version
#   cluster_endpoint_public_access = var.cluster_endpoint_public_access
#   cluster_endpoint_private_access = var.cluster_endpoint_private_access
# 
#   # Networking
#   vpc_id                          = var.vpc_id
#   subnet_ids                      = var.private_subnet_ids
#   control_plane_subnet_ids        = var.private_subnet_ids
#   cluster_additional_security_group_ids = [var.cluster_security_group_id]
# 
#   # Public access CIDRs
#   cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
# 
#   # Encryption
#   cluster_encryption_config = {
#     provider_key_arn = local.kms_key_arn
#     resources        = ["secrets"]
#   }
# 
#   # Logging
#   cluster_enabled_log_types = var.cluster_enabled_log_types
#   # Remove custom KMS key for CloudWatch logs to avoid permission issues
#   # cloudwatch_log_group_kms_key_id = aws_kms_key.eks.arn
#   cloudwatch_log_group_retention_in_days = var.cloudwatch_log_retention_days
# 
#   # IRSA (IAM Roles for Service Accounts)
#   enable_irsa = true
# 
#   # EKS Managed Node Groups will be created separately
#   eks_managed_node_groups = {}
# 
#   # Fargate Profiles (optional)
#   fargate_profiles = var.enable_fargate ? {
#     default = {
#       name = "default"
#       selectors = [
#         {
#           namespace = "kube-system"
#           labels = {
#             "app.kubernetes.io/name" = "aws-load-balancer-controller"
#           }
#         },
#         {
#           namespace = "default"
#         }
#       ]
# 
#       tags = merge(var.tags, {
#         Name = "${var.cluster_name}-fargate-default"
#       })
#     }
#   } : {}
# 
#   # Cluster security group
#   cluster_security_group_name        = "${var.cluster_name}-cluster-sg"
#   cluster_security_group_description = "EKS cluster security group"
#   cluster_security_group_use_name_prefix = false
# 
#   # Node security group
#   node_security_group_name        = "${var.cluster_name}-node-sg"
#   node_security_group_description = "EKS node shared security group"
#   node_security_group_use_name_prefix = false
#   node_security_group_additional_rules = {
#     ingress_self_all = {
#       description = "Node to node all ports/protocols"
#       protocol    = "-1"
#       from_port   = 0
#       to_port     = 0
#       type        = "ingress"
#       self        = true
#     }
#     
#     ingress_cluster_api_ephemeral_ports_tcp = {
#       description                   = "Cluster API to node groups (1025-65535)"
#       protocol                      = "tcp"
#       from_port                     = 1025
#       to_port                       = 65535
#       type                          = "ingress"
#       source_cluster_security_group = true
#     }
# 
#     # Allow ALB to communicate with pods
#     ingress_alb_all = {
#       description                = "ALB to node groups"
#       protocol                   = "tcp"
#       from_port                  = 30000
#       to_port                    = 65535
#       type                       = "ingress"
#       source_security_group_id   = var.alb_security_group_id
#     }
#   }
# 
#   # EKS Addons - Temporarily disable to avoid timeout during initial deployment
#   cluster_addons = {
#     # CoreDNS will be enabled after node groups are ready
#     # coredns = {
#     #   most_recent = true
#     #   configuration_values = jsonencode({
#     #     computeType = var.enable_fargate ? "Fargate" : "ec2"
#     #     resources = {
#     #       limits = {
#     #         cpu    = "0.25"
#     #         memory = "256Mi"
#     #       }
#     #       requests = {
#     #         cpu    = "0.25"
#     #         memory = "256Mi"
#     #       }
#     #     }
#     #   })
#     # }
#     
#     kube-proxy = {
#       most_recent = true
#     }
#     
#     vpc-cni = {
#       most_recent = true
#       configuration_values = jsonencode({
#         env = {
#           ENABLE_POD_ENI                    = "true"
#           ENABLE_PREFIX_DELEGATION          = "true"
#           POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
#         }
#         enableNetworkPolicy = "true"
#       })
#     }
#     
#     # EBS CSI driver will be enabled after node groups and IRSA are ready
#     # aws-ebs-csi-driver = {
#     #   most_recent = true
#     #   service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
#     # }
#     
#     # EFS CSI driver disabled for now
#     # aws-efs-csi-driver = var.enable_efs_csi ? {
#     #   most_recent = true
#     #   service_account_role_arn = module.efs_csi_irsa[0].iam_role_arn
#     # } : {}
#   }
# 
#   # Access entries
#   access_entries = var.access_entries
# 
#   tags = merge(var.tags, {
#     "kubernetes.io/cluster/${var.cluster_name}" = "owned"
#   })
# }

# IRSA modules temporarily disabled during recovery
# Will be re-enabled once cluster module is restored

# # IRSA for EBS CSI Driver
# module "ebs_csi_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "~> 5.20"
# 
#   role_name_prefix = "${var.cluster_name}-ebs-csi-"
# 
#   attach_ebs_csi_policy = true
# 
#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
#     }
#   }
# 
#   tags = var.tags
# }
# 
# # IRSA for EFS CSI Driver (optional)
# module "efs_csi_irsa" {
#   count = var.enable_efs_csi ? 1 : 0
#   
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "~> 5.20"
# 
#   role_name_prefix = "${var.cluster_name}-efs-csi-"
# 
#   attach_efs_csi_policy = true
# 
#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
#     }
#   }
# 
#   tags = var.tags
# }
