# EKS OIDC Provider Module
# Creates an IAM OpenID Connect provider for EKS cluster authentication

# Read the EKS cluster to get OIDC issuer URL
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

# Get the OIDC issuer URL from the cluster
locals {
  oidc_issuer_url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# Get the TLS certificate from the OIDC issuer URL
data "tls_certificate" "oidc" {
  url = local.oidc_issuer_url
}

# Create the IAM OpenID Connect provider
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url = local.oidc_issuer_url

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.oidc.certificates[0].sha1_fingerprint
  ]

  tags = {
    Name        = "${var.cluster_name}-oidc-provider"
    ClusterName = var.cluster_name
    Region      = var.cluster_region
    Purpose     = "eks-oidc-authentication"
  }
}
