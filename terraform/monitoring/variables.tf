# Variables for Monitoring Module (Prometheus/Grafana Stack)

# General configuration
variable "namespace" {
  description = "Kubernetes namespace for monitoring components"
  type        = string
  default     = "monitoring"
}

variable "create_namespace" {
  description = "Whether to create the monitoring namespace"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# Helm configuration
variable "helm_release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "kube-prometheus-stack"
}

variable "chart_version" {
  description = "Version of the kube-prometheus-stack Helm chart"
  type        = string
  default     = "51.2.0"
}

variable "helm_values" {
  description = "Additional Helm values to set"
  type        = map(string)
  default     = {}
}

# Feature toggles
variable "enable_prometheus" {
  description = "Enable Prometheus deployment"
  type        = bool
  default     = true
}

variable "enable_grafana" {
  description = "Enable Grafana deployment"
  type        = bool
  default     = true
}

variable "enable_alertmanager" {
  description = "Enable Alertmanager deployment"
  type        = bool
  default     = true
}

variable "enable_prometheus_operator" {
  description = "Enable Prometheus Operator"
  type        = bool
  default     = true
}

variable "enable_kube_state_metrics" {
  description = "Enable Kube State Metrics"
  type        = bool
  default     = true
}

variable "enable_node_exporter" {
  description = "Enable Node Exporter"
  type        = bool
  default     = true
}

variable "enable_default_rules" {
  description = "Enable default monitoring rules"
  type        = bool
  default     = true
}

variable "enable_alertmanager_rules" {
  description = "Enable Alertmanager rules"
  type        = bool
  default     = true
}

variable "enable_admission_webhooks" {
  description = "Enable admission webhooks for Prometheus Operator"
  type        = bool
  default     = true
}

variable "enable_thanos" {
  description = "Enable Thanos sidecar for Prometheus"
  type        = bool
  default     = false
}

# Storage configuration
variable "create_storage_class" {
  description = "Whether to create a storage class for Prometheus"
  type        = bool
  default     = true
}

# Service Account configuration
variable "create_prometheus_service_account" {
  description = "Whether to create service account for Prometheus"
  type        = bool
  default     = true
}

variable "prometheus_service_account_name" {
  description = "Name of the Prometheus service account"
  type        = string
  default     = "prometheus-kube-prometheus-prometheus"
}

variable "prometheus_service_account_annotations" {
  description = "Annotations for Prometheus service account"
  type        = map(string)
  default     = {}
}

variable "prometheus_role_arn" {
  description = "IAM role ARN for Prometheus service account"
  type        = string
  default     = ""
}

variable "create_grafana_service_account" {
  description = "Whether to create service account for Grafana"
  type        = bool
  default     = true
}

variable "grafana_service_account_name" {
  description = "Name of the Grafana service account"
  type        = string
  default     = "grafana"
}

variable "grafana_service_account_annotations" {
  description = "Annotations for Grafana service account"
  type        = map(string)
  default     = {}
}

variable "grafana_role_arn" {
  description = "IAM role ARN for Grafana service account"
  type        = string
  default     = ""
}

# Grafana admin credentials
variable "create_grafana_admin_secret" {
  description = "Whether to create Grafana admin secret"
  type        = bool
  default     = true
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = "admin123!"
  sensitive   = true
}

# Prometheus configuration
variable "prometheus_replicas" {
  description = "Number of Prometheus replicas"
  type        = number
  default     = 2
}

variable "prometheus_retention" {
  description = "Data retention period for Prometheus"
  type        = string
  default     = "30d"
}

variable "prometheus_retention_size" {
  description = "Maximum size of Prometheus data"
  type        = string
  default     = "50GiB"
}

variable "prometheus_scrape_interval" {
  description = "Global scrape interval for Prometheus"
  type        = string
  default     = "30s"
}

variable "prometheus_evaluation_interval" {
  description = "Global evaluation interval for Prometheus"
  type        = string
  default     = "30s"
}

variable "prometheus_resources" {
  description = "Resource limits and requests for Prometheus"
  type = object({
    limits = optional(object({
      cpu    = optional(string, "2000m")
      memory = optional(string, "8Gi")
    }), {})
    requests = optional(object({
      cpu    = optional(string, "1000m")
      memory = optional(string, "4Gi")
    }), {})
  })
  default = {
    limits = {
      cpu    = "2000m"
      memory = "8Gi"
    }
    requests = {
      cpu    = "1000m"
      memory = "4Gi"
    }
  }
}

variable "prometheus_node_selector" {
  description = "Node selector for Prometheus pods"
  type        = map(string)
  default     = {}
}

variable "prometheus_tolerations" {
  description = "Tolerations for Prometheus pods"
  type = list(object({
    key      = optional(string)
    operator = optional(string)
    value    = optional(string)
    effect   = optional(string)
  }))
  default = []
}

variable "prometheus_affinity" {
  description = "Affinity rules for Prometheus pods"
  type        = any
  default     = {}
}

variable "prometheus_storage" {
  description = "Storage configuration for Prometheus"
  type = object({
    volumeClaimTemplate = object({
      spec = object({
        storageClassName = optional(string, "prometheus-gp3")
        accessModes      = optional(list(string), ["ReadWriteOnce"])
        resources = object({
          requests = object({
            storage = string
          })
        })
      })
    })
  })
  default = {
    volumeClaimTemplate = {
      spec = {
        storageClassName = "prometheus-gp3"
        accessModes      = ["ReadWriteOnce"]
        resources = {
          requests = {
            storage = "50Gi"
          }
        }
      }
    }
  }
}

variable "prometheus_ingress" {
  description = "Ingress configuration for Prometheus"
  type = object({
    enabled = optional(bool, false)
    ingressClassName = optional(string, "alb")
    annotations = optional(map(string), {})
    hosts = optional(list(object({
      host = string
      paths = list(object({
        path = string
        pathType = optional(string, "Prefix")
      }))
    })), [])
    tls = optional(list(object({
      secretName = optional(string)
      hosts = optional(list(string))
    })), [])
  })
  default = {
    enabled = false
  }
}

variable "prometheus_additional_scrape_configs" {
  description = "Additional scrape configs for Prometheus"
  type        = list(any)
  default     = []
}

variable "prometheus_remote_write" {
  description = "Remote write configuration for Prometheus"
  type        = list(any)
  default     = []
}

variable "prometheus_external_labels" {
  description = "External labels for Prometheus"
  type        = map(string)
  default     = {}
}

variable "prometheus_enable_features" {
  description = "Feature flags for Prometheus"
  type        = list(string)
  default     = []
}

# Alertmanager configuration
variable "alertmanager_replicas" {
  description = "Number of Alertmanager replicas"
  type        = number
  default     = 3
}

variable "alertmanager_retention" {
  description = "Data retention period for Alertmanager"
  type        = string
  default     = "120h"
}

variable "alertmanager_resources" {
  description = "Resource limits and requests for Alertmanager"
  type = object({
    limits = optional(object({
      cpu    = optional(string, "100m")
      memory = optional(string, "128Mi")
    }), {})
    requests = optional(object({
      cpu    = optional(string, "50m")
      memory = optional(string, "64Mi")
    }), {})
  })
  default = {
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
    requests = {
      cpu    = "50m"
      memory = "64Mi"
    }
  }
}

variable "alertmanager_node_selector" {
  description = "Node selector for Alertmanager pods"
  type        = map(string)
  default     = {}
}

variable "alertmanager_tolerations" {
  description = "Tolerations for Alertmanager pods"
  type = list(object({
    key      = optional(string)
    operator = optional(string)
    value    = optional(string)
    effect   = optional(string)
  }))
  default = []
}

variable "alertmanager_affinity" {
  description = "Affinity rules for Alertmanager pods"
  type        = any
  default     = {}
}

variable "alertmanager_storage" {
  description = "Storage configuration for Alertmanager"
  type = object({
    volumeClaimTemplate = object({
      spec = object({
        storageClassName = optional(string, "prometheus-gp3")
        accessModes      = optional(list(string), ["ReadWriteOnce"])
        resources = object({
          requests = object({
            storage = string
          })
        })
      })
    })
  })
  default = {
    volumeClaimTemplate = {
      spec = {
        storageClassName = "prometheus-gp3"
        accessModes      = ["ReadWriteOnce"]
        resources = {
          requests = {
            storage = "2Gi"
          }
        }
      }
    }
  }
}

variable "alertmanager_ingress" {
  description = "Ingress configuration for Alertmanager"
  type = object({
    enabled = optional(bool, false)
    ingressClassName = optional(string, "alb")
    annotations = optional(map(string), {})
    hosts = optional(list(object({
      host = string
      paths = list(object({
        path = string
        pathType = optional(string, "Prefix")
      }))
    })), [])
    tls = optional(list(object({
      secretName = optional(string)
      hosts = optional(list(string))
    })), [])
  })
  default = {
    enabled = false
  }
}

variable "alertmanager_config" {
  description = "Alertmanager configuration"
  type        = any
  default = {
    global = {
      smtp_smarthost = "localhost:587"
      smtp_from = "alertmanager@example.org"
    }
    route = {
      group_by = ["alertname"]
      group_wait = "10s"
      group_interval = "10s"
      repeat_interval = "1h"
      receiver = "web.hook"
    }
    receivers = [
      {
        name = "web.hook"
        webhook_configs = [
          {
            url = "http://127.0.0.1:5001/"
          }
        ]
      }
    ]
  }
}

# Grafana configuration
variable "grafana_resources" {
  description = "Resource limits and requests for Grafana"
  type = object({
    limits = optional(object({
      cpu    = optional(string, "500m")
      memory = optional(string, "1Gi")
    }), {})
    requests = optional(object({
      cpu    = optional(string, "250m")
      memory = optional(string, "512Mi")
    }), {})
  })
  default = {
    limits = {
      cpu    = "500m"
      memory = "1Gi"
    }
    requests = {
      cpu    = "250m"
      memory = "512Mi"
    }
  }
}

variable "grafana_node_selector" {
  description = "Node selector for Grafana pods"
  type        = map(string)
  default     = {}
}

variable "grafana_tolerations" {
  description = "Tolerations for Grafana pods"
  type = list(object({
    key      = optional(string)
    operator = optional(string)
    value    = optional(string)
    effect   = optional(string)
  }))
  default = []
}

variable "grafana_affinity" {
  description = "Affinity rules for Grafana pods"
  type        = any
  default     = {}
}

variable "grafana_persistence" {
  description = "Persistence configuration for Grafana"
  type = object({
    enabled = optional(bool, true)
    storageClassName = optional(string, "prometheus-gp3")
    accessModes = optional(list(string), ["ReadWriteOnce"])
    size = optional(string, "10Gi")
  })
  default = {
    enabled = true
    storageClassName = "prometheus-gp3"
    accessModes = ["ReadWriteOnce"]
    size = "10Gi"
  }
}

variable "grafana_ingress" {
  description = "Ingress configuration for Grafana"
  type = object({
    enabled = optional(bool, false)
    ingressClassName = optional(string, "alb")
    annotations = optional(map(string), {})
    hosts = optional(list(object({
      host = string
      paths = list(object({
        path = string
        pathType = optional(string, "Prefix")
      }))
    })), [])
    tls = optional(list(object({
      secretName = optional(string)
      hosts = optional(list(string))
    })), [])
  })
  default = {
    enabled = false
  }
}

variable "grafana_ini" {
  description = "Grafana configuration (grafana.ini)"
  type = object({
    security = optional(object({
      admin_user = optional(string, "admin")
      admin_password = optional(string, "admin")
    }), {})
    users = optional(object({
      allow_sign_up = optional(bool, false)
      auto_assign_org_role = optional(string, "Viewer")
    }), {})
    auth = optional(object({
      disable_login_form = optional(bool, false)
    }), {})
    auth_anonymous = optional(object({
      enabled = optional(bool, false)
      org_role = optional(string, "Viewer")
    }), {})
    server = optional(object({
      root_url = optional(string, "")
      serve_from_sub_path = optional(bool, false)
    }), {})
    smtp = optional(object({
      enabled = optional(bool, false)
      host = optional(string, "localhost:587")
      user = optional(string, "")
      password = optional(string, "")
      from_address = optional(string, "admin@grafana.localhost")
    }), {})
  })
  default = {
    security = {
      admin_user = "admin"
      admin_password = "admin"
    }
    users = {
      allow_sign_up = false
      auto_assign_org_role = "Viewer"
    }
    "auth.anonymous" = {
      enabled = false
      org_role = "Viewer"
    }
  }
}

variable "additional_datasources" {
  description = "Additional datasources for Grafana"
  type = list(object({
    name = string
    type = string
    url = string
    access = optional(string, "proxy")
    isDefault = optional(bool, false)
    basicAuth = optional(bool, false)
    basicAuthUser = optional(string, "")
    basicAuthPassword = optional(string, "")
    withCredentials = optional(bool, false)
    jsonData = optional(map(any), {})
    secureJsonData = optional(map(string), {})
  }))
  default = []
}

variable "grafana_dashboards" {
  description = "Grafana dashboards to install"
  type        = map(any)
  default = {
    default = {
      k8s-cluster-rsrc-use = {
        gnetId = 15757
        revision = 1
        datasource = "Prometheus"
      }
      k8s-node-rsrc-use = {
        gnetId = 15759
        revision = 1
        datasource = "Prometheus"
      }
      k8s-resources-cluster = {
        gnetId = 15760
        revision = 1
        datasource = "Prometheus"
      }
      k8s-resources-namespace = {
        gnetId = 15758
        revision = 1
        datasource = "Prometheus"
      }
      k8s-resources-pod = {
        gnetId = 15761
        revision = 1
        datasource = "Prometheus"
      }
    }
  }
}

variable "grafana_plugins" {
  description = "List of Grafana plugins to install"
  type        = list(string)
  default = [
    "grafana-clock-panel",
    "grafana-piechart-panel"
  ]
}

variable "grafana_env" {
  description = "Environment variables for Grafana"
  type        = map(string)
  default     = {}
}

variable "grafana_extra_configmap_mounts" {
  description = "Extra configmap mounts for Grafana"
  type = list(object({
    name = string
    mountPath = string
    configMap = string
    readOnly = optional(bool, true)
  }))
  default = []
}

# Prometheus Operator configuration
variable "prometheus_operator_resources" {
  description = "Resource limits and requests for Prometheus Operator"
  type = object({
    limits = optional(object({
      cpu    = optional(string, "200m")
      memory = optional(string, "200Mi")
    }), {})
    requests = optional(object({
      cpu    = optional(string, "100m")
      memory = optional(string, "100Mi")
    }), {})
  })
  default = {
    limits = {
      cpu    = "200m"
      memory = "200Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "100Mi"
    }
  }
}

variable "prometheus_operator_node_selector" {
  description = "Node selector for Prometheus Operator pods"
  type        = map(string)
  default     = {}
}

variable "prometheus_operator_tolerations" {
  description = "Tolerations for Prometheus Operator pods"
  type = list(object({
    key      = optional(string)
    operator = optional(string)
    value    = optional(string)
    effect   = optional(string)
  }))
  default = []
}

variable "prometheus_operator_affinity" {
  description = "Affinity rules for Prometheus Operator pods"
  type        = any
  default     = {}
}

# Node Exporter configuration
variable "node_exporter_resources" {
  description = "Resource limits and requests for Node Exporter"
  type = object({
    limits = optional(object({
      cpu    = optional(string, "250m")
      memory = optional(string, "180Mi")
    }), {})
    requests = optional(object({
      cpu    = optional(string, "102m")
      memory = optional(string, "180Mi")
    }), {})
  })
  default = {
    limits = {
      cpu    = "250m"
      memory = "180Mi"
    }
    requests = {
      cpu    = "102m"
      memory = "180Mi"
    }
  }
}

variable "node_exporter_tolerations" {
  description = "Additional tolerations for Node Exporter pods"
  type = list(object({
    key      = optional(string)
    operator = optional(string)
    value    = optional(string)
    effect   = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
