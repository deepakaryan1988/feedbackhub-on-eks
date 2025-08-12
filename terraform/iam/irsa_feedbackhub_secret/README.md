# IRSA FeedbackHub Secret Module

This Terraform module creates an AWS Secrets Manager secret for storing the MongoDB URI and configures IRSA (IAM Roles for Service Accounts) to allow secure access from Kubernetes pods.

## Features

- **AWS Secrets Manager**: Stores MongoDB URI as a JSON secret
- **IRSA Integration**: IAM role with OIDC trust policy for secure pod access
- **Kubernetes Resources**: Creates namespace and ServiceAccount with proper annotations
- **Least Privilege**: IAM policy only allows access to the specific secret

## Module Structure

```
irsa_feedbackhub_secret/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Input variable definitions
├── outputs.tf           # Output definitions
├── versions.tf          # Provider version requirements
├── dev.auto.tfvars     # Development configuration example
├── tfvars.template     # Template for configuration
└── README.md           # This documentation
```

## Usage

```hcl
module "feedbackhub_secret" {
  source = "./terraform/iam/irsa_feedbackhub_secret"
  
  cluster_name        = "feedbackhub-dev-cluster"
  cluster_region      = "us-east-1"
  oidc_provider_arn  = module.eks_oidc.oidc_provider_arn
  oidc_provider_url  = module.eks_oidc.oidc_provider_url
  namespace           = "feedbackhub"
  service_account     = "feedbackhub-app"
  mongodb_uri         = var.mongodb_uri
  create_namespace    = true
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |
| kubernetes | >= 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| cluster_region | AWS region where the EKS cluster is located | `string` | n/a | yes |
| oidc_provider_arn | ARN of the EKS OIDC provider | `string` | n/a | yes |
| oidc_provider_url | URL of the EKS OIDC provider | `string` | n/a | yes |
| namespace | Kubernetes namespace for the FeedbackHub application | `string` | n/a | yes |
| service_account | Name of the ServiceAccount that will access the secret | `string` | n/a | yes |
| mongodb_uri | MongoDB connection URI (marked as sensitive) | `string` | n/a | yes |
| create_namespace | Whether to create the Kubernetes namespace | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_arn | ARN of the created AWS Secrets Manager secret |
| role_arn | ARN of the created IAM role for secret access |
| namespace | Kubernetes namespace where resources are created |
| service_account_name | Name of the ServiceAccount with IRSA annotation |
| secret_name | Name of the created AWS Secrets Manager secret |

## Secret Structure

The MongoDB URI is stored in AWS Secrets Manager as a JSON string:

```json
{
  "MONGODB_URI": "mongodb://username:password@hostname:27017/database?authSource=admin"
}
```

## IAM Permissions

The created IAM role has the following permissions:
- `secretsmanager:GetSecretValue` on the specific secret ARN

## Security Features

- **Sensitive Variable**: MongoDB URI is marked as sensitive and won't appear in logs
- **Least Privilege**: IAM role only has access to the specific secret
- **IRSA Integration**: Uses OIDC federation for secure pod authentication
- **Resource Isolation**: Secret name includes namespace and service account for isolation

## Dependencies

This module depends on:
- EKS cluster with OIDC provider configured
- `eks_oidc` module output for OIDC provider details
- AWS provider configured with appropriate permissions
- Kubernetes provider (configured dynamically from EKS cluster)

## Configuration

1. Copy `tfvars.template` to `dev.auto.tfvars`
2. Update the values with your actual configuration
3. Ensure the `mongodb_uri` contains your real MongoDB connection string
4. Run `terraform plan` to validate the configuration
5. Run `terraform apply` to create the resources

## Files Created

- **AWS Secrets Manager Secret**: `${namespace}/${service_account}/mongodb-uri`
- **IAM Role**: `${cluster_name}-${namespace}-${service_account}-secret-role`
- **IAM Policy**: Inline policy for secret access
- **Kubernetes Namespace**: `var.namespace` (if `create_namespace = true`)
- **ServiceAccount**: `var.service_account` with IRSA annotation
