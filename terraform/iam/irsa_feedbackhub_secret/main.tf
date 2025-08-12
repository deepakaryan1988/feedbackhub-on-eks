# IRSA FeedbackHub Secret Module
# Creates AWS Secrets Manager secret for MongoDB URI and IAM role for secure access

# Configure Kubernetes provider dynamically using EKS cluster data
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Create AWS Secrets Manager secret for MongoDB URI
resource "aws_secretsmanager_secret" "mongodb_uri" {
  name        = "${var.namespace}/${var.service_account}/mongodb-uri"
  description = "MongoDB connection URI for FeedbackHub application"
  region      = var.cluster_region

  tags = {
    Name           = "${var.namespace}-${var.service_account}-mongodb-uri"
    ClusterName    = var.cluster_name
    Region         = var.cluster_region
    Purpose        = "feedbackhub-mongodb-secret"
    Namespace      = var.namespace
    ServiceAccount = var.service_account
  }
}

# Store the MongoDB URI as a JSON string in the secret
resource "aws_secretsmanager_secret_version" "mongodb_uri" {
  secret_id = aws_secretsmanager_secret.mongodb_uri.id
  secret_string = jsonencode({
    MONGODB_URI = var.mongodb_uri
  })
}

# Create IAM role with IRSA trust policy for the service account
resource "aws_iam_role" "feedbackhub_secret" {
  name = "${var.cluster_name}-${var.namespace}-${var.service_account}-secret-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account}"
        }
      }
    }]
  })

  tags = {
    Name           = "${var.cluster_name}-${var.namespace}-${var.service_account}-secret-role"
    ClusterName    = var.cluster_name
    Region         = var.cluster_region
    Purpose        = "feedbackhub-secret-access"
    Namespace      = var.namespace
    ServiceAccount = var.service_account
  }
}

# Create inline policy for accessing the specific secret
resource "aws_iam_role_policy" "feedbackhub_secret_access" {
  name = "${var.cluster_name}-${var.namespace}-${var.service_account}-secret-policy"
  role = aws_iam_role.feedbackhub_secret.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = aws_secretsmanager_secret.mongodb_uri.arn
    }]
  })
}

# Create Kubernetes namespace if it doesn't exist
resource "kubernetes_namespace" "feedbackhub" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      app = "feedbackhub"
      env = "dev"
    }
  }
}

# Create ServiceAccount with IRSA annotation
resource "kubernetes_service_account" "feedbackhub" {
  metadata {
    name      = var.service_account
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.feedbackhub_secret.arn
    }
    labels = {
      app = "feedbackhub"
      env = "dev"
    }
  }

  depends_on = [kubernetes_namespace.feedbackhub]
}
