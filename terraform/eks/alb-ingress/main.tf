# AWS Load Balancer Controller Module
# This module deploys the AWS Load Balancer Controller (ALB Ingress Controller) using Helm

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Service Account for AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  count = var.create_service_account ? 1 : 0

  metadata {
    name      = var.service_account_name
    namespace = var.namespace
    labels = merge(var.labels, {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/part-of"   = "aws-load-balancer-controller"
    })
    annotations = merge(var.service_account_annotations, {
      "eks.amazonaws.com/role-arn" = var.role_arn
    })
  }

  automount_service_account_token = true
}

# AWS Load Balancer Controller Helm Release
resource "helm_release" "aws_load_balancer_controller" {
  name       = var.helm_release_name
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.chart_version
  namespace  = var.namespace

  # Wait for service account if we're creating it
  depends_on = [kubernetes_service_account.aws_load_balancer_controller]

  values = [
    yamlencode({
      clusterName = var.cluster_name

      serviceAccount = {
        create = false # We manage the service account separately
        name   = var.service_account_name
        annotations = merge(var.service_account_annotations, {
          "eks.amazonaws.com/role-arn" = var.role_arn
        })
      }

      # Pod configuration
      replicaCount = var.replica_count

      image = {
        repository = var.image_repository
        tag        = var.image_tag
        pullPolicy = "IfNotPresent"
      }

      # Resource limits
      resources = var.resources

      # Node selection
      nodeSelector = var.node_selector
      tolerations  = var.tolerations
      affinity     = var.affinity

      # Security context
      securityContext = {
        allowPrivilegeEscalation = false
        readOnlyRootFilesystem   = true
        runAsNonRoot             = true
        runAsUser                = 65534
        capabilities = {
          drop = ["ALL"]
        }
      }

      # Pod security context
      podSecurityContext = {
        fsGroup = 65534
      }

      # Additional configuration
      region = data.aws_region.current.name

      vpcId = var.vpc_id

      # Feature gates
      enableShield      = var.enable_shield
      enableWaf         = var.enable_waf
      enableWafv2       = var.enable_wafv2
      enableCertManager = var.enable_cert_manager

      # Ingress class configuration
      ingressClass = var.ingress_class_name
      ingressClassParams = {
        name = var.ingress_class_params_name
        spec = var.ingress_class_params_spec
      }

      # Webhook configuration
      webhookConfig = {
        failurePolicy = var.webhook_failure_policy
      }

      # Logging
      logLevel = var.log_level

      # Metrics
      enableMetrics   = var.enable_metrics
      metricsBindAddr = var.metrics_bind_addr

      # Health probes
      livenessProbe = {
        failureThreshold = 3
        httpGet = {
          path   = "/healthz"
          port   = 61779
          scheme = "HTTP"
        }
        initialDelaySeconds = 30
        periodSeconds       = 10
        successThreshold    = 1
        timeoutSeconds      = 10
      }

      readinessProbe = {
        failureThreshold = 3
        httpGet = {
          path   = "/readyz"
          port   = 61779
          scheme = "HTTP"
        }
        initialDelaySeconds = 10
        periodSeconds       = 10
        successThreshold    = 1
        timeoutSeconds      = 10
      }

      # Additional arguments
      additionalArgs = var.additional_args

      # Explicitly enable IngressClass creation via Helm chart
      createIngressClassResource = true
      ingressClass               = var.ingress_class_name

      # Configure IngressClass as default  
      ingressClassConfig = {
        default = true
      }

      # Configure IngressClassParams
      ingressClassParams = {
        create = var.create_ingress_class_params
        name   = var.ingress_class_params_name
        spec   = var.ingress_class_params_spec
      }
    })
  ]

  # Set values directly for better terraform tracking
  dynamic "set" {
    for_each = var.helm_values
    content {
      name  = set.key
      value = set.value
    }
  }

  # Wait for deployment to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  # Clean up on destroy
  cleanup_on_fail = true
  force_update    = false
  recreate_pods   = false
}

# Note: IngressClass, IngressClassParams, and CRDs are managed by the Helm chart
# The aws-load-balancer-controller Helm chart automatically creates:
# - IngressClass with createIngressClassResource: true (default)
# - IngressClassParams with ingressClassParams.create: true (default)  
# - All required CRDs during installation
# This eliminates timing issues with kubernetes_manifest resources
