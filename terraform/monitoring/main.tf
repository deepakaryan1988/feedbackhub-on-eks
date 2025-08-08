# Monitoring Module - Prometheus and Grafana Stack
# This module deploys a comprehensive monitoring stack using kube-prometheus-stack

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

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = merge(var.labels, {
      "name"                               = var.namespace
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    })
  }
}

# Service Account for Prometheus
resource "kubernetes_service_account" "prometheus" {
  count = var.create_prometheus_service_account ? 1 : 0

  metadata {
    name      = var.prometheus_service_account_name
    namespace = var.namespace
    labels = merge(var.labels, {
      "app.kubernetes.io/name"    = "prometheus"
      "app.kubernetes.io/part-of" = "kube-prometheus-stack"
    })
    annotations = merge(var.prometheus_service_account_annotations, {
      "eks.amazonaws.com/role-arn" = var.prometheus_role_arn
    })
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# Service Account for Grafana
resource "kubernetes_service_account" "grafana" {
  count = var.create_grafana_service_account ? 1 : 0

  metadata {
    name      = var.grafana_service_account_name
    namespace = var.namespace
    labels = merge(var.labels, {
      "app.kubernetes.io/name"    = "grafana"
      "app.kubernetes.io/part-of" = "kube-prometheus-stack"
    })
    annotations = merge(var.grafana_service_account_annotations, {
      "eks.amazonaws.com/role-arn" = var.grafana_role_arn
    })
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# Grafana admin password secret
resource "kubernetes_secret" "grafana_admin" {
  count = var.create_grafana_admin_secret ? 1 : 0

  metadata {
    name      = "grafana-admin-secret"
    namespace = var.namespace
  }

  data = {
    admin-user     = var.grafana_admin_user
    admin-password = var.grafana_admin_password
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.monitoring]
}

# Storage class for Prometheus (if using EBS)
resource "kubernetes_storage_class" "prometheus_gp3" {
  count = var.create_storage_class ? 1 : 0

  metadata {
    name = "prometheus-gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type       = "gp3"
    iops       = "3000"
    throughput = "125"
    encrypted  = "true"
  }
}

# kube-prometheus-stack Helm release
resource "helm_release" "kube_prometheus_stack" {
  name       = var.helm_release_name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  namespace  = var.namespace

  depends_on = [
    kubernetes_namespace.monitoring,
    kubernetes_service_account.prometheus,
    kubernetes_service_account.grafana,
    kubernetes_secret.grafana_admin,
    kubernetes_storage_class.prometheus_gp3
  ]

  values = [
    yamlencode({
      # Global configuration
      fullnameOverride  = ""
      namespaceOverride = var.namespace

      # Common labels
      commonLabels = var.labels

      # Default rules
      defaultRules = {
        create = var.enable_default_rules
        rules = {
          alertmanager                = var.enable_alertmanager_rules
          etcd                        = false # Not applicable for managed EKS
          configReloaders             = true
          general                     = true
          k8s                         = true
          kubeApiserverAvailability   = true
          kubeApiserverBurnrate       = true
          kubeApiserverHistogram      = true
          kubeApiserverSlos           = true
          kubelet                     = true
          kubeProxy                   = false # Often not present in EKS
          kubePrometheusGeneral       = true
          kubePrometheusNodeRecording = true
          kubernetesApps              = true
          kubernetesResources         = true
          kubernetesStorage           = true
          kubernetesSystem            = true
          kubeScheduler               = false # Not accessible in managed EKS
          kubeStateMetrics            = true
          network                     = true
          node                        = true
          nodeExporterAlerting        = true
          nodeExporterRecording       = true
          prometheus                  = true
          prometheusOperator          = true
        }
      }

      # Alertmanager configuration
      alertmanager = {
        enabled          = var.enable_alertmanager
        fullnameOverride = "alertmanager"

        serviceAccount = {
          create = false
          name   = var.prometheus_service_account_name
        }

        ingress = var.alertmanager_ingress

        alertmanagerSpec = {
          replicas  = var.alertmanager_replicas
          retention = var.alertmanager_retention

          resources = var.alertmanager_resources

          nodeSelector = var.alertmanager_node_selector
          tolerations  = var.alertmanager_tolerations
          affinity     = var.alertmanager_affinity

          storage = var.alertmanager_storage

          securityContext = {
            runAsNonRoot = true
            runAsUser    = 65534
            fsGroup      = 65534
          }

          podSecurityContext = {
            runAsNonRoot = true
            runAsUser    = 65534
            fsGroup      = 65534
          }
        }

        config = var.alertmanager_config
      }

      # Grafana configuration
      grafana = {
        enabled          = var.enable_grafana
        fullnameOverride = "grafana"

        serviceAccount = {
          create = false
          name   = var.grafana_service_account_name
        }

        admin = {
          existingSecret = var.create_grafana_admin_secret ? "grafana-admin-secret" : ""
          userKey        = var.create_grafana_admin_secret ? "admin-user" : ""
          passwordKey    = var.create_grafana_admin_secret ? "admin-password" : ""
        }

        ingress = var.grafana_ingress

        resources = var.grafana_resources

        nodeSelector = var.grafana_node_selector
        tolerations  = var.grafana_tolerations
        affinity     = var.grafana_affinity

        persistence = var.grafana_persistence

        securityContext = {
          runAsNonRoot = true
          runAsUser    = 472
          runAsGroup   = 472
          fsGroup      = 472
        }

        # Grafana configuration
        "grafana.ini" = var.grafana_ini

        # Data sources
        datasources = {
          "datasources.yaml" = {
            apiVersion = 1
            datasources = concat(
              [
                {
                  name      = "Prometheus"
                  type      = "prometheus"
                  url       = "http://prometheus-kube-prometheus-prometheus:9090"
                  access    = "proxy"
                  isDefault = true
                }
              ],
              var.additional_datasources
            )
          }
        }

        # Dashboard providers
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [
              {
                name            = "default"
                orgId           = 1
                folder          = ""
                type            = "file"
                disableDeletion = false
                editable        = true
                options = {
                  path = "/var/lib/grafana/dashboards/default"
                }
              }
            ]
          }
        }

        # Dashboard ConfigMaps
        dashboards = var.grafana_dashboards

        # Plugins
        plugins = var.grafana_plugins

        # Environment variables
        env = var.grafana_env

        # Extra configmap mounts
        extraConfigmapMounts = var.grafana_extra_configmap_mounts
      }

      # Kube State Metrics
      kubeStateMetrics = {
        enabled = var.enable_kube_state_metrics
      }

      # Node Exporter
      nodeExporter = {
        enabled = var.enable_node_exporter
        operatingSystems = {
          linux = {
            enabled = true
          }
          darwin = {
            enabled = false
          }
        }
      }

      # Prometheus Node Exporter
      "prometheus-node-exporter" = {
        fullnameOverride = "node-exporter"

        podLabels = var.labels

        resources = var.node_exporter_resources

        tolerations = concat(
          [
            {
              effect   = "NoSchedule"
              operator = "Exists"
            }
          ],
          var.node_exporter_tolerations
        )
      }

      # Prometheus Operator
      prometheusOperator = {
        enabled          = var.enable_prometheus_operator
        fullnameOverride = "prometheus-operator"

        serviceAccount = {
          create = true
        }

        resources = var.prometheus_operator_resources

        nodeSelector = var.prometheus_operator_node_selector
        tolerations  = var.prometheus_operator_tolerations
        affinity     = var.prometheus_operator_affinity

        securityContext = {
          runAsNonRoot = true
          runAsUser    = 65534
          runAsGroup   = 65534
        }

        # Admission webhooks
        admissionWebhooks = {
          enabled = var.enable_admission_webhooks
          patch = {
            enabled = true
          }
        }
      }

      # Prometheus configuration
      prometheus = {
        enabled          = var.enable_prometheus
        fullnameOverride = "prometheus"

        serviceAccount = {
          create = false
          name   = var.prometheus_service_account_name
        }

        ingress = var.prometheus_ingress

        prometheusSpec = {
          replicas      = var.prometheus_replicas
          retention     = var.prometheus_retention
          retentionSize = var.prometheus_retention_size

          scrapeInterval     = var.prometheus_scrape_interval
          evaluationInterval = var.prometheus_evaluation_interval

          resources = var.prometheus_resources

          nodeSelector = var.prometheus_node_selector
          tolerations  = var.prometheus_tolerations
          affinity     = var.prometheus_affinity

          storageSpec = var.prometheus_storage

          securityContext = {
            runAsNonRoot = true
            runAsUser    = 65534
            fsGroup      = 65534
          }

          podSecurityContext = {
            runAsNonRoot = true
            runAsUser    = 65534
            fsGroup      = 65534
          }

          # Service monitor selectors
          serviceMonitorSelectorNilUsesHelmValues = false
          serviceMonitorSelector                  = {}
          serviceMonitorNamespaceSelector         = {}

          # Pod monitor selectors
          podMonitorSelectorNilUsesHelmValues = false
          podMonitorSelector                  = {}
          podMonitorNamespaceSelector         = {}

          # Rule selectors
          ruleSelectorNilUsesHelmValues = false
          ruleSelector                  = {}
          ruleNamespaceSelector         = {}

          # Additional scrape configs
          additionalScrapeConfigs = var.prometheus_additional_scrape_configs

          # Remote write
          remoteWrite = var.prometheus_remote_write

          # External labels
          externalLabels = var.prometheus_external_labels

          # WAL compression
          walCompression = true

          # Enable features
          enableFeatures = var.prometheus_enable_features
        }

        thanosService = var.enable_thanos ? {
          enabled = true
        } : {}

        thanosServiceMonitor = var.enable_thanos ? {
          enabled = true
        } : {}
      }
    })
  ]

  # Set individual values for better tracking
  dynamic "set" {
    for_each = var.helm_values
    content {
      name  = set.key
      value = set.value
    }
  }

  # Wait for deployment
  wait          = true
  wait_for_jobs = true
  timeout       = 1200

  cleanup_on_fail = true
  force_update    = false
  recreate_pods   = false
}
