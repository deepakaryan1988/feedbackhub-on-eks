# Configure AWS provider
provider "aws" {
  region = var.cluster_region
}

# Get EKS cluster data for Kubernetes provider
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}

# Get the current OIDC provider ID dynamically
data "aws_eks_cluster" "current" {
  name = var.cluster_name
}

locals {
  oidc_provider = replace(data.aws_eks_cluster.current.identity[0].oidc[0].issuer, "https://", "")
}

# Create IAM role with proper trust policy
resource "aws_iam_role" "feedbackhub_secret" {
  name = "${var.cluster_name}-${var.namespace}-${var.service_account}-secret-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account}"
          }
        }
      }
    ]
  })

  tags = {
    Name          = "${var.cluster_name}-${var.namespace}-${var.service_account}-secret-role"
    ClusterName   = var.cluster_name
    Namespace     = var.namespace
    ServiceAccount = var.service_account
    Purpose       = "feedbackhub-secret-access"
    Region        = var.cluster_region
  }
}

# Create IAM policy for Secrets Manager access
resource "aws_iam_role_policy" "feedbackhub_secret" {
  name = "${var.cluster_name}-${var.namespace}-${var.service_account}-secret-policy"
  role = aws_iam_role.feedbackhub_secret.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.cluster_region}:${data.aws_caller_identity.current.account_id}:secret:feedbackhub/feedbackhub-app/mongodb-uri*"
        ]
      }
    ]
  })
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Create namespace
resource "kubernetes_namespace" "feedbackhub" {
  metadata {
    name = var.namespace
    labels = {
      app = "feedbackhub"
    }
  }
}

# Create service account with IRSA annotation
resource "kubernetes_service_account" "feedbackhub_app" {
  metadata {
    name      = var.service_account
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.feedbackhub_secret.arn
    }
  }
  depends_on = [kubernetes_namespace.feedbackhub]
}

# Create deployment
resource "kubernetes_deployment" "feedbackhub" {
  metadata {
    name      = "feedbackhub"
    namespace = var.namespace
    labels = {
      app = "feedbackhub"
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "feedbackhub"
      }
    }

    template {
      metadata {
        labels = {
          app = "feedbackhub"
        }
      }

      spec {
        service_account_name = var.service_account

        container {
          image = var.image
          name  = "feedbackhub-app"

          port {
            container_port = var.container_port
          }

          env {
            name  = "AWS_REGION"
            value = var.cluster_region
          }

          env {
            name  = "FEEDBACKHUB_SECRET_NAME"
            value = "feedbackhub/feedbackhub-app/mongodb-uri"
          }

          # Note: MONGODB_URI is not set here - the app will:
          # 1. On AWS: Retrieve it from Secrets Manager using FEEDBACKHUB_SECRET_NAME
          # 2. On local: Use host.docker.internal:27017 or MONGODB_URI env var

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = var.health_path
              port = var.container_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = var.health_path
              port = var.container_port
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.feedbackhub, kubernetes_service_account.feedbackhub_app]
}

# Create service
resource "kubernetes_service" "feedbackhub_svc" {
  metadata {
    name      = "feedbackhub-svc"
    namespace = var.namespace
    labels = {
      app = "feedbackhub"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "feedbackhub"
    }

    port {
      port        = var.container_port
      target_port = var.container_port
      protocol    = "TCP"
    }
  }

  depends_on = [kubernetes_namespace.feedbackhub, kubernetes_deployment.feedbackhub]
}
