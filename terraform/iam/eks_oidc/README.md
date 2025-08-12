# EKS OIDC Provider Module

This Terraform module creates an IAM OpenID Connect provider for EKS cluster authentication, enabling pods to assume IAM roles using IRSA (IAM Roles for Service Accounts).

## Features

- Automatically reads EKS cluster OIDC issuer URL
- Dynamically retrieves TLS certificate thumbprint (no hardcoding)
- Creates IAM OIDC provider with proper configuration
- Supports tagging and naming conventions

## Usage

```hcl
module "eks_oidc" {
  source = "./terraform/iam/eks_oidc"
  
  cluster_name   = "feedbackhub-dev"
  cluster_region = "us-east-1"
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| cluster_name | Name of the EKS cluster | string | Yes |
| cluster_region | AWS region where the EKS cluster is located | string | Yes |

## Outputs

| Name | Description |
|------|-------------|
| oidc_provider_arn | ARN of the created IAM OpenID Connect provider |
| oidc_provider_url | URL of the created IAM OpenID Connect provider |

## Requirements

- AWS provider configured
- EKS cluster must exist and be accessible
- TLS provider for certificate validation

## Example

```bash
# Navigate to the module directory
cd terraform/iam/eks_oidc

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

## Notes

- The module automatically discovers the OIDC issuer URL from the EKS cluster
- TLS certificate thumbprint is dynamically retrieved, ensuring security
- Tags are applied for resource identification and cost tracking
