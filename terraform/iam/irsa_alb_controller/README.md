# IRSA ALB Controller Module

This Terraform module creates an IAM role with IRSA (IAM Roles for Service Accounts) trust policy for the AWS Load Balancer Controller, enabling it to manage AWS Application Load Balancers and Network Load Balancers.

## Features

- Creates IAM role with proper IRSA trust policy
- Downloads official ALB Controller IAM policy from upstream repository
- Attaches policy to role for least-privilege access
- Supports custom service account namespace and name
- Follows tagging conventions for resource identification

## Prerequisites

- EKS cluster must exist
- OIDC provider must be created (use the `eks_oidc` module first)
- AWS provider configured with appropriate permissions

## Usage

```hcl
module "alb_controller_irsa" {
  source = "./terraform/iam/irsa_alb_controller"
  
  cluster_name        = "feedbackhub-dev"
  cluster_region      = "us-east-1"
  oidc_provider_arn  = module.eks_oidc.oidc_provider_arn
  oidc_provider_url  = module.eks_oidc.oidc_provider_url
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| cluster_name | Name of the EKS cluster | string | Yes | - |
| cluster_region | AWS region where the EKS cluster is located | string | Yes | - |
| oidc_provider_arn | ARN of the EKS OIDC provider | string | Yes | - |
| oidc_provider_url | URL of the EKS OIDC provider | string | Yes | - |
| service_account_namespace | Kubernetes namespace for the service account | string | No | "kube-system" |
| service_account_name | Name of the service account | string | No | "aws-load-balancer-controller" |

## Outputs

| Name | Description |
|------|-------------|
| alb_controller_role_arn | ARN of the created IAM role for ALB Controller |
| service_account_namespace | Namespace of the service account |
| service_account_name | Name of the service account |

## Workflow

1. **Create OIDC Provider**: First apply the `eks_oidc` module
2. **Get OIDC Outputs**: Note the `oidc_provider_arn` and `oidc_provider_url`
3. **Update Variables**: Uncomment and populate the OIDC values in `dev.auto.tfvars`
4. **Apply Module**: Run `terraform apply` to create the role and policy

## Example

```bash
# Navigate to the module directory
cd terraform/iam/irsa_alb_controller

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

## Notes

- The module downloads the official ALB Controller policy at plan/apply time
- The trust policy uses `StringEquals` condition with the OIDC provider URL and service account
- All resources are properly tagged for cost tracking and identification
- The role follows IRSA best practices for EKS service account authentication
