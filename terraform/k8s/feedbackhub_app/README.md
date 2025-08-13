# FeedbackHub App Terraform Module

This Terraform module deploys the FeedbackHub application to an EKS cluster.

## Features

- Creates a dedicated namespace for the FeedbackHub app
- Deploys the FeedbackHub application with configurable replicas
- Sets up health checks (liveness and readiness probes)
- Configures service account with IRSA for AWS Secrets Manager access
- Creates a ClusterIP service for internal communication
- Configures minimal resource requests and limits

## Usage

**Note: The example below uses dummy data. Replace with your actual values.**

```hcl
module "feedbackhub_app" {
  source = "./terraform/k8s/feedbackhub_app"

  cluster_name    = "my-eks-cluster"        # DUMMY DATA - replace with your cluster name
  cluster_region  = "us-west-2"             # DUMMY DATA - replace with your region
  image           = "123456789012.dkr.ecr.us-west-2.amazonaws.com/feedbackhub:latest"  # DUMMY DATA - replace with your image
  replicas        = 2
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| cluster_region | AWS region where the EKS cluster is located | `string` | n/a | yes |
| namespace | Kubernetes namespace for the FeedbackHub app | `string` | `"feedbackhub"` | no |
| service_account | Kubernetes service account name for the FeedbackHub app | `string` | `"feedbackhub-app"` | no |
| image | Docker image for the FeedbackHub app | `string` | n/a | yes |
| replicas | Number of replicas for the FeedbackHub deployment | `number` | `1` | no |
| container_port | Container port for the FeedbackHub app | `number` | `3000` | no |
| health_path | Health check path for liveness and readiness probes | `string` | `"/api/health"` | no |

## Outputs

| Name | Description |
|------|-------------|
| deployment_name | Name of the FeedbackHub deployment |
| service_name | Name of the FeedbackHub service |
| namespace | Namespace where the FeedbackHub app is deployed |
| service_account_name | Name of the service account used by the FeedbackHub app |

## Prerequisites

- EKS cluster must be running and accessible
- AWS provider must be configured with appropriate credentials
- The service account role (`feedbackhub-app-role`) must exist and have permissions to access AWS Secrets Manager
- The secret `feedbackhub/feedbackhub-app/mongodb-uri` must exist in AWS Secrets Manager

## Health Checks

The module configures both liveness and readiness probes:

- **Liveness Probe**: HTTP GET to `/api/health` every 10 seconds after 30 second initial delay
- **Readiness Probe**: HTTP GET to `/api/health` every 5 seconds after 5 second initial delay

## Resource Configuration

- **CPU Requests**: 100m
- **Memory Requests**: 128Mi
- **CPU Limits**: 500m
- **Memory Limits**: 512Mi

## Environment Variables

- `AWS_REGION`: Set to the cluster region
- `FEEDBACKHUB_SECRET_NAME`: Set to `"feedbackhub/feedbackhub-app/mongodb-uri"`

The application will use IRSA (IAM Roles for Service Accounts) to authenticate with AWS and retrieve the MongoDB connection string from Secrets Manager.
