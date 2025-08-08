# Logging Module - Loki Stack with CloudWatch Integration

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
  }
}

# Create namespace for logging if requested
resource "kubernetes_namespace" "logging" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = merge(
      {
        "name"                         = var.namespace
        "app.kubernetes.io/managed-by" = "terraform"
        "app.kubernetes.io/part-of"    = "logging-stack"
      },
      var.namespace_labels
    )
    annotations = var.namespace_annotations
  }
}

# Service account for Loki with IRSA
resource "kubernetes_service_account" "loki" {
  count = var.create_loki_service_account ? 1 : 0

  metadata {
    name      = var.loki_service_account_name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "loki"
      "app.kubernetes.io/component"  = "logging"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    annotations = merge(
      var.loki_role_arn != null ? {
        "eks.amazonaws.com/role-arn" = var.loki_role_arn
      } : {},
      var.loki_service_account_annotations
    )
  }

  depends_on = [kubernetes_namespace.logging]
}

# Service account for Promtail with IRSA
resource "kubernetes_service_account" "promtail" {
  count = var.create_promtail_service_account ? 1 : 0

  metadata {
    name      = var.promtail_service_account_name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "promtail"
      "app.kubernetes.io/component"  = "logging"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    annotations = merge(
      var.promtail_role_arn != null ? {
        "eks.amazonaws.com/role-arn" = var.promtail_role_arn
      } : {},
      var.promtail_service_account_annotations
    )
  }

  depends_on = [kubernetes_namespace.logging]
}

# Service account for Fluent Bit with IRSA
resource "kubernetes_service_account" "fluent_bit" {
  count = var.create_fluent_bit_service_account ? 1 : 0

  metadata {
    name      = var.fluent_bit_service_account_name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "fluent-bit"
      "app.kubernetes.io/component"  = "logging"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    annotations = merge(
      var.fluent_bit_role_arn != null ? {
        "eks.amazonaws.com/role-arn" = var.fluent_bit_role_arn
      } : {},
      var.fluent_bit_service_account_annotations
    )
  }

  depends_on = [kubernetes_namespace.logging]
}

# Storage class for logging (GP3 optimized)
resource "kubernetes_storage_class" "logging_gp3" {
  count = var.create_storage_class ? 1 : 0

  metadata {
    name = "gp3-logging"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "logging-stack"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type       = "gp3"
    iops       = "3000"
    throughput = "125"
    encrypted  = "true"
  }
}

# Loki stack deployment using Helm
resource "helm_release" "loki_stack" {
  count = var.enable_loki ? 1 : 0

  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = var.loki_chart_version
  namespace  = var.namespace

  # Wait for namespace to be created
  depends_on = [kubernetes_namespace.logging]

  # Timeout and cleanup settings
  timeout         = 600
  cleanup_on_fail = true
  wait            = true
  wait_for_jobs   = true

  values = concat([
    yamlencode({
      # Loki configuration
      loki = {
        enabled = true

        # Use custom service account if created
        serviceAccount = var.create_loki_service_account ? {
          create      = false
          name        = tostring(kubernetes_service_account.loki[0].metadata[0].name)
          annotations = {}
          } : {
          create = true
          name   = var.loki_service_account_name
          annotations = var.loki_role_arn != null ? {
            "eks.amazonaws.com/role-arn" = var.loki_role_arn
          } : {}
        }

        # Image configuration
        image = var.loki_image

        # Security context
        securityContext          = var.loki_security_context
        containerSecurityContext = var.loki_container_security_context

        # Resource allocation
        resources = var.loki_resources

        # Persistence configuration
        persistence = var.loki_persistence

        # Loki configuration
        config = var.loki_config

        # Service configuration
        service = var.loki_service

        # Ingress configuration
        ingress = var.loki_ingress

        # Node selection and affinity
        nodeSelector = var.loki_node_selector
        tolerations  = var.loki_tolerations
        affinity     = var.loki_affinity

        # Pod annotations and labels
        podAnnotations = var.loki_pod_annotations
        podLabels      = var.loki_pod_labels

        # Environment variables
        env = var.loki_env
      }

      # Promtail configuration (log collector)
      promtail = {
        enabled = var.enable_promtail

        # Use custom service account if created
        serviceAccount = var.create_promtail_service_account ? {
          create      = false
          name        = tostring(kubernetes_service_account.promtail[0].metadata[0].name)
          annotations = {}
          } : {
          create = true
          name   = var.promtail_service_account_name
          annotations = var.promtail_role_arn != null ? {
            "eks.amazonaws.com/role-arn" = var.promtail_role_arn
          } : {}
        }

        # Image configuration
        image = var.promtail_image

        # Security context
        securityContext          = var.promtail_security_context
        containerSecurityContext = var.promtail_container_security_context

        # Resource allocation
        resources = var.promtail_resources

        # Configuration
        config = var.promtail_config

        # Node selection and affinity
        nodeSelector = var.promtail_node_selector
        tolerations  = var.promtail_tolerations
        affinity     = var.promtail_affinity

        # Pod annotations and labels
        podAnnotations = var.promtail_pod_annotations
        podLabels      = var.promtail_pod_labels

        # Environment variables
        env = var.promtail_env

        # Volume mounts for container logs
        volumeMounts = var.promtail_volume_mounts
        volumes      = var.promtail_volumes

        # Service monitor for Prometheus integration
        serviceMonitor = var.promtail_service_monitor
      }

      # Fluent Bit configuration (alternative log collector)
      fluent-bit = {
        enabled = var.enable_fluent_bit

        # Use custom service account if created
        serviceAccount = var.create_fluent_bit_service_account ? {
          create      = false
          name        = tostring(kubernetes_service_account.fluent_bit[0].metadata[0].name)
          annotations = {}
          } : {
          create = true
          name   = var.fluent_bit_service_account_name
          annotations = var.fluent_bit_role_arn != null ? {
            "eks.amazonaws.com/role-arn" = var.fluent_bit_role_arn
          } : {}
        }

        # Image configuration
        image = var.fluent_bit_image

        # Security context
        securityContext = var.fluent_bit_security_context

        # Resource allocation
        resources = var.fluent_bit_resources

        # Configuration
        config = var.fluent_bit_config

        # Node selection and affinity
        nodeSelector = var.fluent_bit_node_selector
        tolerations  = var.fluent_bit_tolerations
        affinity     = var.fluent_bit_affinity

        # Pod annotations and labels
        podAnnotations = var.fluent_bit_pod_annotations
        podLabels      = var.fluent_bit_pod_labels

        # Service monitor for Prometheus integration
        serviceMonitor = var.fluent_bit_service_monitor
      }

      # Grafana integration (if not using external Grafana)
      grafana = {
        enabled = var.enable_grafana_for_loki

        # Use existing Grafana if available
        sidecar = {
          datasources = {
            enabled = true
            label   = "grafana_datasource"
          }
        }
      }

      # Log gateway configuration
      gateway = {
        enabled = var.enable_gateway

        # Image configuration
        image = var.gateway_image

        # Security context
        securityContext = var.gateway_security_context

        # Resource allocation
        resources = var.gateway_resources

        # Service configuration
        service = var.gateway_service

        # Ingress configuration
        ingress = var.gateway_ingress

        # Basic auth configuration
        basicAuth = var.gateway_basic_auth

        # Node selection and affinity
        nodeSelector = var.gateway_node_selector
        tolerations  = var.gateway_tolerations
        affinity     = var.gateway_affinity
      }

      # Test pods configuration
      test = {
        enabled = var.enable_test_pods
      }
    })
    ],
    length(var.helm_additional_values) > 0 ? [yamlencode(var.helm_additional_values)] : [],
  length(var.helm_additional_sensitive_values) > 0 ? [yamlencode(var.helm_additional_sensitive_values)] : [])

  # Additional values merged via concat for compatibility
}

# CloudWatch log group for centralized logging
resource "aws_cloudwatch_log_group" "cluster_logs" {
  count = var.enable_cloudwatch_logging ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_retention_days

  tags = merge(
    var.tags,
    {
      Name      = "${var.cluster_name}-cluster-logs"
      Component = "logging"
      ManagedBy = "terraform"
    }
  )
}

resource "aws_cloudwatch_log_group" "application_logs" {
  count = var.enable_cloudwatch_logging ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/application"
  retention_in_days = var.cloudwatch_retention_days

  tags = merge(
    var.tags,
    {
      Name      = "${var.cluster_name}-application-logs"
      Component = "logging"
      ManagedBy = "terraform"
    }
  )
}

resource "aws_cloudwatch_log_group" "dataplane_logs" {
  count = var.enable_cloudwatch_logging ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/dataplane"
  retention_in_days = var.cloudwatch_retention_days

  tags = merge(
    var.tags,
    {
      Name      = "${var.cluster_name}-dataplane-logs"
      Component = "logging"
      ManagedBy = "terraform"
    }
  )
}

# CloudWatch log streams for different log types
resource "aws_cloudwatch_log_stream" "api_server" {
  count          = var.enable_cloudwatch_logging ? 1 : 0
  name           = "api-server"
  log_group_name = aws_cloudwatch_log_group.cluster_logs[0].name
}

resource "aws_cloudwatch_log_stream" "audit" {
  count          = var.enable_cloudwatch_logging ? 1 : 0
  name           = "audit"
  log_group_name = aws_cloudwatch_log_group.cluster_logs[0].name
}

resource "aws_cloudwatch_log_stream" "authenticator" {
  count          = var.enable_cloudwatch_logging ? 1 : 0
  name           = "authenticator"
  log_group_name = aws_cloudwatch_log_group.cluster_logs[0].name
}

resource "aws_cloudwatch_log_stream" "controllerManager" {
  count          = var.enable_cloudwatch_logging ? 1 : 0
  name           = "controllerManager"
  log_group_name = aws_cloudwatch_log_group.cluster_logs[0].name
}

resource "aws_cloudwatch_log_stream" "scheduler" {
  count          = var.enable_cloudwatch_logging ? 1 : 0
  name           = "scheduler"
  log_group_name = aws_cloudwatch_log_group.cluster_logs[0].name
}
