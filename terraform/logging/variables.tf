# Variables for Logging Module

# General Configuration
variable "namespace" {
  description = "Kubernetes namespace for logging components"
  type        = string
  default     = "logging"
}

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
  default     = true
}

variable "namespace_labels" {
  description = "Additional labels for the namespace"
  type        = map(string)
  default     = {}
}

variable "namespace_annotations" {
  description = "Additional annotations for the namespace"
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# Storage Configuration
variable "create_storage_class" {
  description = "Whether to create a storage class for logging"
  type        = bool
  default     = true
}

# Service Account Configuration
variable "create_loki_service_account" {
  description = "Whether to create service account for Loki"
  type        = bool
  default     = true
}

variable "loki_service_account_name" {
  description = "Name of the Loki service account"
  type        = string
  default     = "loki"
}

variable "loki_service_account_annotations" {
  description = "Additional annotations for Loki service account"
  type        = map(string)
  default     = {}
}

variable "loki_role_arn" {
  description = "IAM role ARN for Loki service account (IRSA)"
  type        = string
  default     = null
}

variable "create_promtail_service_account" {
  description = "Whether to create service account for Promtail"
  type        = bool
  default     = true
}

variable "promtail_service_account_name" {
  description = "Name of the Promtail service account"
  type        = string
  default     = "promtail"
}

variable "promtail_service_account_annotations" {
  description = "Additional annotations for Promtail service account"
  type        = map(string)
  default     = {}
}

variable "promtail_role_arn" {
  description = "IAM role ARN for Promtail service account (IRSA)"
  type        = string
  default     = null
}

variable "create_fluent_bit_service_account" {
  description = "Whether to create service account for Fluent Bit"
  type        = bool
  default     = false
}

variable "fluent_bit_service_account_name" {
  description = "Name of the Fluent Bit service account"
  type        = string
  default     = "fluent-bit"
}

variable "fluent_bit_service_account_annotations" {
  description = "Additional annotations for Fluent Bit service account"
  type        = map(string)
  default     = {}
}

variable "fluent_bit_role_arn" {
  description = "IAM role ARN for Fluent Bit service account (IRSA)"
  type        = string
  default     = null
}

# Loki Configuration
variable "enable_loki" {
  description = "Whether to enable Loki"
  type        = bool
  default     = true
}

variable "loki_chart_version" {
  description = "Version of the Loki stack Helm chart"
  type        = string
  default     = "2.9.11"
}

variable "loki_image" {
  description = "Loki image configuration"
  type = object({
    repository = string
    tag        = string
    pullPolicy = string
  })
  default = {
    repository = "grafana/loki"
    tag        = "2.9.2"
    pullPolicy = "IfNotPresent"
  }
}

variable "loki_security_context" {
  description = "Security context for Loki pods"
  type = object({
    runAsUser              = number
    runAsGroup             = number
    runAsNonRoot           = bool
    readOnlyRootFilesystem = bool
    fsGroup                = number
  })
  default = {
    runAsUser              = 10001
    runAsGroup             = 10001
    runAsNonRoot           = true
    readOnlyRootFilesystem = true
    fsGroup                = 10001
  }
}

variable "loki_container_security_context" {
  description = "Container security context for Loki"
  type = object({
    runAsUser                = number
    runAsGroup               = number
    runAsNonRoot             = bool
    readOnlyRootFilesystem   = bool
    allowPrivilegeEscalation = bool
    capabilities = object({
      drop = list(string)
    })
  })
  default = {
    runAsUser                = 10001
    runAsGroup               = 10001
    runAsNonRoot             = true
    readOnlyRootFilesystem   = true
    allowPrivilegeEscalation = false
    capabilities = {
      drop = ["ALL"]
    }
  }
}

variable "loki_resources" {
  description = "Resource allocation for Loki"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
  default = {
    requests = {
      memory = "256Mi"
      cpu    = "100m"
    }
    limits = {
      memory = "512Mi"
      cpu    = "500m"
    }
  }
}

variable "loki_persistence" {
  description = "Persistence configuration for Loki"
  type = object({
    enabled          = bool
    storageClassName = string
    size             = string
    accessModes      = list(string)
  })
  default = {
    enabled          = true
    storageClassName = "gp3-logging"
    size             = "10Gi"
    accessModes      = ["ReadWriteOnce"]
  }
}

variable "loki_config" {
  description = "Loki configuration"
  type = object({
    auth_enabled = bool
    server = object({
      http_listen_port = number
      grpc_listen_port = number
    })
    common = object({
      path_prefix = string
      storage = object({
        filesystem = object({
          chunks_directory = string
          rules_directory  = string
        })
      })
      replication_factor = number
      ring = object({
        instance_addr = string
        kvstore = object({
          store = string
        })
      })
    })
    schema_config = object({
      configs = list(object({
        from         = string
        store        = string
        object_store = string
        schema       = string
        index = object({
          prefix = string
          period = string
        })
      }))
    })
    ruler = object({
      alertmanager_url = string
    })
    limits_config = object({
      enforce_metric_name           = bool
      reject_old_samples            = bool
      reject_old_samples_max_age    = string
      ingestion_rate_mb             = number
      ingestion_burst_size_mb       = number
      max_concurrent_tail_requests  = number
      max_cache_freshness_per_query = string
    })
  })
  default = {
    auth_enabled = false
    server = {
      http_listen_port = 3100
      grpc_listen_port = 9096
    }
    common = {
      path_prefix = "/tmp/loki"
      storage = {
        filesystem = {
          chunks_directory = "/tmp/loki/chunks"
          rules_directory  = "/tmp/loki/rules"
        }
      }
      replication_factor = 1
      ring = {
        instance_addr = "127.0.0.1"
        kvstore = {
          store = "inmemory"
        }
      }
    }
    schema_config = {
      configs = [
        {
          from         = "2020-10-24"
          store        = "boltdb-shipper"
          object_store = "filesystem"
          schema       = "v11"
          index = {
            prefix = "index_"
            period = "24h"
          }
        }
      ]
    }
    ruler = {
      alertmanager_url = "http://prometheus-kube-prometheus-alertmanager.monitoring.svc.cluster.local:9093"
    }
    limits_config = {
      enforce_metric_name           = false
      reject_old_samples            = true
      reject_old_samples_max_age    = "168h"
      ingestion_rate_mb             = 4
      ingestion_burst_size_mb       = 6
      max_concurrent_tail_requests  = 10
      max_cache_freshness_per_query = "10m"
    }
  }
}

variable "loki_service" {
  description = "Loki service configuration"
  type = object({
    type        = string
    port        = number
    annotations = map(string)
  })
  default = {
    type        = "ClusterIP"
    port        = 3100
    annotations = {}
  }
}

variable "loki_ingress" {
  description = "Loki ingress configuration"
  type = object({
    enabled     = bool
    annotations = map(string)
    hosts = list(object({
      host = string
      paths = list(object({
        path     = string
        pathType = string
      }))
    }))
    tls = list(object({
      secretName = string
      hosts      = list(string)
    }))
  })
  default = {
    enabled     = false
    annotations = {}
    hosts       = []
    tls         = []
  }
}

variable "loki_node_selector" {
  description = "Node selector for Loki pods"
  type        = map(string)
  default     = {}
}

variable "loki_tolerations" {
  description = "Tolerations for Loki pods"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = []
}

variable "loki_affinity" {
  description = "Affinity rules for Loki pods"
  type        = any
  default     = {}
}

variable "loki_pod_annotations" {
  description = "Additional annotations for Loki pods"
  type        = map(string)
  default     = {}
}

variable "loki_pod_labels" {
  description = "Additional labels for Loki pods"
  type        = map(string)
  default     = {}
}

variable "loki_env" {
  description = "Environment variables for Loki"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Promtail Configuration
variable "enable_promtail" {
  description = "Whether to enable Promtail"
  type        = bool
  default     = true
}

variable "promtail_image" {
  description = "Promtail image configuration"
  type = object({
    repository = string
    tag        = string
    pullPolicy = string
  })
  default = {
    repository = "grafana/promtail"
    tag        = "2.9.2"
    pullPolicy = "IfNotPresent"
  }
}

variable "promtail_security_context" {
  description = "Security context for Promtail pods"
  type = object({
    runAsUser              = number
    runAsGroup             = number
    runAsNonRoot           = bool
    readOnlyRootFilesystem = bool
    fsGroup                = number
  })
  default = {
    runAsUser              = 0
    runAsGroup             = 0
    runAsNonRoot           = false
    readOnlyRootFilesystem = true
    fsGroup                = 0
  }
}

variable "promtail_container_security_context" {
  description = "Container security context for Promtail"
  type = object({
    runAsUser                = number
    runAsGroup               = number
    runAsNonRoot             = bool
    readOnlyRootFilesystem   = bool
    allowPrivilegeEscalation = bool
    capabilities = object({
      drop = list(string)
    })
  })
  default = {
    runAsUser                = 0
    runAsGroup               = 0
    runAsNonRoot             = false
    readOnlyRootFilesystem   = true
    allowPrivilegeEscalation = false
    capabilities = {
      drop = ["ALL"]
    }
  }
}

variable "promtail_resources" {
  description = "Resource allocation for Promtail"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
  default = {
    requests = {
      memory = "128Mi"
      cpu    = "100m"
    }
    limits = {
      memory = "256Mi"
      cpu    = "200m"
    }
  }
}

variable "promtail_config" {
  description = "Promtail configuration"
  type = object({
    server = object({
      http_listen_port = number
      grpc_listen_port = number
    })
    clients = list(object({
      url = string
    }))
    positions = object({
      filename = string
    })
    scrape_configs = list(object({
      job_name = string
      static_configs = list(object({
        targets = list(string)
        labels  = map(string)
      }))
      pipeline_stages = list(any)
    }))
  })
  default = {
    server = {
      http_listen_port = 3101
      grpc_listen_port = 9095
    }
    clients = [
      {
        url = "http://loki:3100/loki/api/v1/push"
      }
    ]
    positions = {
      filename = "/tmp/positions.yaml"
    }
    scrape_configs = [
      {
        job_name = "kubernetes-pods"
        static_configs = [
          {
            targets = ["localhost"]
            labels = {
              job      = "kubernetes-pods"
              __path__ = "/var/log/pods/*/*/*.log"
            }
          }
        ]
        pipeline_stages = [
          {
            cri = {}
          }
        ]
      }
    ]
  }
}

variable "promtail_node_selector" {
  description = "Node selector for Promtail pods"
  type        = map(string)
  default     = {}
}

variable "promtail_tolerations" {
  description = "Tolerations for Promtail pods"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = [
    {
      key      = ""
      operator = "Exists"
      value    = ""
      effect   = "NoSchedule"
    }
  ]
}

variable "promtail_affinity" {
  description = "Affinity rules for Promtail pods"
  type        = any
  default     = {}
}

variable "promtail_pod_annotations" {
  description = "Additional annotations for Promtail pods"
  type        = map(string)
  default     = {}
}

variable "promtail_pod_labels" {
  description = "Additional labels for Promtail pods"
  type        = map(string)
  default     = {}
}

variable "promtail_env" {
  description = "Environment variables for Promtail"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "promtail_volume_mounts" {
  description = "Additional volume mounts for Promtail"
  type = list(object({
    name      = string
    mountPath = string
    readOnly  = bool
  }))
  default = [
    {
      name      = "varlog"
      mountPath = "/var/log"
      readOnly  = true
    },
    {
      name      = "varlibdockercontainers"
      mountPath = "/var/lib/docker/containers"
      readOnly  = true
    }
  ]
}

variable "promtail_volumes" {
  description = "Additional volumes for Promtail"
  type = list(object({
    name = string
    hostPath = object({
      path = string
    })
  }))
  default = [
    {
      name = "varlog"
      hostPath = {
        path = "/var/log"
      }
    },
    {
      name = "varlibdockercontainers"
      hostPath = {
        path = "/var/lib/docker/containers"
      }
    }
  ]
}

variable "promtail_service_monitor" {
  description = "ServiceMonitor configuration for Promtail"
  type = object({
    enabled = bool
    labels  = map(string)
  })
  default = {
    enabled = true
    labels = {
      "app.kubernetes.io/name" = "promtail"
    }
  }
}

# Fluent Bit Configuration
variable "enable_fluent_bit" {
  description = "Whether to enable Fluent Bit"
  type        = bool
  default     = false
}

variable "fluent_bit_image" {
  description = "Fluent Bit image configuration"
  type = object({
    repository = string
    tag        = string
    pullPolicy = string
  })
  default = {
    repository = "fluent/fluent-bit"
    tag        = "2.2.0"
    pullPolicy = "IfNotPresent"
  }
}

variable "fluent_bit_security_context" {
  description = "Security context for Fluent Bit pods"
  type = object({
    runAsUser              = number
    runAsGroup             = number
    runAsNonRoot           = bool
    readOnlyRootFilesystem = bool
    fsGroup                = number
  })
  default = {
    runAsUser              = 0
    runAsGroup             = 0
    runAsNonRoot           = false
    readOnlyRootFilesystem = true
    fsGroup                = 0
  }
}

variable "fluent_bit_resources" {
  description = "Resource allocation for Fluent Bit"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
  default = {
    requests = {
      memory = "64Mi"
      cpu    = "50m"
    }
    limits = {
      memory = "128Mi"
      cpu    = "100m"
    }
  }
}

variable "fluent_bit_config" {
  description = "Fluent Bit configuration"
  type        = any
  default = {
    service = {
      Flush        = 1
      Log_Level    = "info"
      Daemon       = "off"
      Parsers_File = "parsers.conf"
      HTTP_Server  = "On"
      HTTP_Listen  = "0.0.0.0"
      HTTP_Port    = 2020
    }
    inputs = [
      {
        Name            = "tail"
        Path            = "/var/log/containers/*.log"
        Parser          = "cri"
        Tag             = "kube.*"
        Mem_Buf_Limit   = "50MB"
        Skip_Long_Lines = "On"
      }
    ]
    filters = [
      {
        Name            = "kubernetes"
        Match           = "kube.*"
        Kube_URL        = "https://kubernetes.default.svc:443"
        Kube_CA_File    = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
        Kube_Token_File = "/var/run/secrets/kubernetes.io/serviceaccount/token"
        Kube_Tag_Prefix = "kube.var.log.containers."
        Merge_Log       = "On"
        Keep_Log        = "Off"
      }
    ]
    outputs = [
      {
        Name                   = "loki"
        Match                  = "*"
        Host                   = "loki"
        Port                   = 3100
        Labels                 = "job=fluent-bit"
        Auto_Kubernetes_Labels = "on"
      }
    ]
  }
}

variable "fluent_bit_node_selector" {
  description = "Node selector for Fluent Bit pods"
  type        = map(string)
  default     = {}
}

variable "fluent_bit_tolerations" {
  description = "Tolerations for Fluent Bit pods"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = [
    {
      key      = ""
      operator = "Exists"
      value    = ""
      effect   = "NoSchedule"
    }
  ]
}

variable "fluent_bit_affinity" {
  description = "Affinity rules for Fluent Bit pods"
  type        = any
  default     = {}
}

variable "fluent_bit_pod_annotations" {
  description = "Additional annotations for Fluent Bit pods"
  type        = map(string)
  default     = {}
}

variable "fluent_bit_pod_labels" {
  description = "Additional labels for Fluent Bit pods"
  type        = map(string)
  default     = {}
}

variable "fluent_bit_service_monitor" {
  description = "ServiceMonitor configuration for Fluent Bit"
  type = object({
    enabled = bool
    labels  = map(string)
  })
  default = {
    enabled = true
    labels = {
      "app.kubernetes.io/name" = "fluent-bit"
    }
  }
}

# Grafana Integration
variable "enable_grafana_for_loki" {
  description = "Whether to enable Grafana integration for Loki (if not using external Grafana)"
  type        = bool
  default     = false
}

# Gateway Configuration
variable "enable_gateway" {
  description = "Whether to enable Loki gateway"
  type        = bool
  default     = false
}

variable "gateway_image" {
  description = "Gateway image configuration"
  type = object({
    repository = string
    tag        = string
    pullPolicy = string
  })
  default = {
    repository = "nginx"
    tag        = "1.25.3-alpine"
    pullPolicy = "IfNotPresent"
  }
}

variable "gateway_security_context" {
  description = "Security context for Gateway pods"
  type = object({
    runAsUser              = number
    runAsGroup             = number
    runAsNonRoot           = bool
    readOnlyRootFilesystem = bool
    fsGroup                = number
  })
  default = {
    runAsUser              = 101
    runAsGroup             = 101
    runAsNonRoot           = true
    readOnlyRootFilesystem = true
    fsGroup                = 101
  }
}

variable "gateway_resources" {
  description = "Resource allocation for Gateway"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
  default = {
    requests = {
      memory = "64Mi"
      cpu    = "50m"
    }
    limits = {
      memory = "128Mi"
      cpu    = "100m"
    }
  }
}

variable "gateway_service" {
  description = "Gateway service configuration"
  type = object({
    type        = string
    port        = number
    annotations = map(string)
  })
  default = {
    type        = "ClusterIP"
    port        = 80
    annotations = {}
  }
}

variable "gateway_ingress" {
  description = "Gateway ingress configuration"
  type = object({
    enabled     = bool
    annotations = map(string)
    hosts = list(object({
      host = string
      paths = list(object({
        path     = string
        pathType = string
      }))
    }))
    tls = list(object({
      secretName = string
      hosts      = list(string)
    }))
  })
  default = {
    enabled     = false
    annotations = {}
    hosts       = []
    tls         = []
  }
}

variable "gateway_basic_auth" {
  description = "Basic auth configuration for Gateway"
  type = object({
    enabled  = bool
    username = string
    password = string
  })
  default = {
    enabled  = false
    username = ""
    password = ""
  }
  sensitive = true
}

variable "gateway_node_selector" {
  description = "Node selector for Gateway pods"
  type        = map(string)
  default     = {}
}

variable "gateway_tolerations" {
  description = "Tolerations for Gateway pods"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = []
}

variable "gateway_affinity" {
  description = "Affinity rules for Gateway pods"
  type        = any
  default     = {}
}

# Test Configuration
variable "enable_test_pods" {
  description = "Whether to enable test pods"
  type        = bool
  default     = false
}

# CloudWatch Integration
variable "enable_cloudwatch_logging" {
  description = "Whether to enable CloudWatch logging"
  type        = bool
  default     = true
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# Helm Configuration
variable "helm_additional_values" {
  description = "Additional Helm values"
  type        = map(string)
  default     = {}
}

variable "helm_additional_sensitive_values" {
  description = "Additional sensitive Helm values"
  type        = map(string)
  default     = {}
  sensitive   = true
}
