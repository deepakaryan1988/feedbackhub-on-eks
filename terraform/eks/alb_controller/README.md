# EKS ALB Controller Module

This Terraform module installs the AWS Load Balancer Controller on an EKS cluster using Helm, with proper IRSA (IAM Roles for Service Accounts) configuration.

## Features

- Configures Kubernetes and Helm providers from EKS cluster data
- Creates Kubernetes service account with IRSA role annotation
- Installs AWS Load Balancer Controller Helm chart from official EKS charts repository
- Sets proper values for cluster name, region, VPC ID, and service account
- Configures resource limits and replica count for production readiness

## Prerequisites

- EKS cluster must exist and be accessible
- IRSA role must be created (use the `irsa_alb_controller` module first)
- VPC ID must be available (from network module)
- AWS provider configured with appropriate permissions

## Usage

```hcl
module "alb_controller" {
  source = "./terraform/eks/alb_controller"
  
  cluster_name           = "feedbackhub-dev"
  cluster_region         = "us-east-1"
  alb_controller_role_arn = module.alb_controller_irsa.alb_controller_role_arn
  vpc_id                 = module.network.vpc_id
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| cluster_name | Name of the EKS cluster | string | Yes | - |
| cluster_region | AWS region where the EKS cluster is located | string | Yes | - |
| alb_controller_role_arn | ARN of the IAM role for the ALB Controller | string | Yes | - |
| vpc_id | VPC ID where the EKS cluster is deployed | string | Yes | - |
| chart_version | Version of the Helm chart to install | string | No | "1.13.4" |

## Outputs

| Name | Description |
|------|-------------|
| service_account_name | Name of the created Kubernetes service account |
| service_account_namespace | Namespace of the created Kubernetes service account |
| helm_release_name | Name of the Helm release |
| chart_version | Version of the Helm chart that was installed |

## Workflow

1. **Create IRSA Role**: First apply the `irsa_alb_controller` module
2. **Get VPC ID**: Ensure VPC ID is available from network module
3. **Update Variables**: Populate the role ARN and VPC ID in `dev.auto.tfvars`
4. **Apply Module**: Run `terraform apply` to install the controller

## Important Upgrade Notes

### CRD Updates Required for Upgrades

When upgrading the AWS Load Balancer Controller chart, you may need to apply CRD updates manually, especially for `TargetGroupBinding` resources.

**Current Chart Version**: 1.13.4 (as of today from ArtifactHub)

**For Upgrades**: Apply CRDs manually using:
```bash
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
```

This ensures that all Custom Resource Definitions are up-to-date before upgrading the controller.

## Example

```bash
# Navigate to the module directory
cd terraform/eks/alb_controller

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

## Verification

After successful deployment, verify the controller is running:
```bash
kubectl -n kube-system get deploy aws-load-balancer-controller
```

You should see the deployment in READY state.

## Notes

- The module automatically configures providers from EKS cluster data
- Service account is created with proper IRSA annotations
- Helm chart is installed with production-ready resource limits
- Chart version is pinned to 1.13.4 but can be overridden
- All resources are properly tagged and labeled
