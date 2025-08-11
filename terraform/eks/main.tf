terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
  }

  backend "local" {}
}

provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "network" {
  backend = "local"
  config  = { path = "../network/terraform.tfstate" }
}

locals {
  name       = "${var.project}-${var.env}"
  subnet_ids = data.terraform_remote_state.network.outputs.public_subnet_ids
  common_tags = {
    project = var.project
    env     = var.env
    owner   = var.owner
    Name    = local.name
  }
}

# IAM role for EKS cluster
resource "aws_iam_role" "cluster" {
  name = "${local.name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# EKS cluster
resource "aws_eks_cluster" "this" {
  name     = local.name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = local.subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]

  tags = local.common_tags
}

# IAM role for node group
resource "aws_iam_role" "node_group" {
  name = "${local.name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "node_group_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  policy_arn = each.value
  role       = aws_iam_role.node_group.name
}

# EKS node group
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.name}-ng1"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = local.subnet_ids

  instance_types = var.instance_types
  ami_type       = "AL2_ARM_64"
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_desired
    min_size     = var.node_min
    max_size     = var.node_max
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.node_group_policies
  ]

  tags = local.common_tags
}

# EKS addons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"

  depends_on = [aws_eks_node_group.this]

  tags = local.common_tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"

  depends_on = [aws_eks_node_group.this]

  tags = local.common_tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"

  depends_on = [aws_eks_node_group.this]

  tags = local.common_tags
}

