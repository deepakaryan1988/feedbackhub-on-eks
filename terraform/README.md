# Terraform Modules for FeedbackHub on EKS

This directory contains Terraform modules for deploying FeedbackHub on Amazon EKS with proper security and infrastructure as code practices.

## 🚨 Security Notice

**Never commit `.tfvars` files to version control!** They may contain sensitive information and environment-specific values.

## 📁 Module Structure

```
terraform/
├── iam/
│   ├── eks_oidc/           # EKS OIDC Provider
│   └── irsa_alb_controller/ # IRSA Role for ALB Controller
├── eks/
│   └── alb_controller/     # ALB Controller Helm Installation
├── eks/                    # EKS Cluster
└── network/                # VPC and Networking
```

## 🔐 Security Best Practices

1. **Use Template Files**: Copy `tfvars.template` files to `dev.auto.tfvars`
2. **Environment Variables**: Use `TF_VAR_*` for sensitive values
3. **Remote State**: Store Terraform state securely (S3 + DynamoDB)
4. **IAM Least Privilege**: All modules follow least privilege principles

## 🚀 Deployment Workflow

### Phase 1: Infrastructure Foundation
```bash
# 1. Deploy network infrastructure
cd terraform/network
terraform init && terraform plan && terraform apply

# 2. Deploy EKS cluster
cd terraform/eks
terraform init && terraform plan && terraform apply
```

### Phase 2: Security & IAM
```bash
# 3. Create OIDC provider
cd terraform/iam/eks_oidc
cp tfvars.template dev.auto.tfvars
# Edit dev.auto.tfvars with actual values
terraform init && terraform plan && terraform apply

# 4. Create IRSA role for ALB Controller
cd terraform/iam/irsa_alb_controller
cp tfvars.template dev.auto.tfvars
# Edit dev.auto.tfvars with OIDC outputs
terraform init && terraform plan && terraform apply
```

### Phase 3: Application Components
```bash
# 5. Install ALB Controller
cd terraform/eks/alb_controller
cp tfvars.template dev.auto.tfvars
# Edit dev.auto.tfvars with role ARN and VPC ID
terraform init && terraform plan && terraform apply
```

## 📋 Using Template Files

Each module includes a `tfvars.template` file that shows:
- Required variables
- Example values
- Placeholder formats

**To use:**
```bash
cd terraform/iam/eks_oidc
cp tfvars.template dev.auto.tfvars
# Edit dev.auto.tfvars with your actual values
```

## 🔧 Environment Variables

For sensitive values, use environment variables:
```bash
export TF_VAR_cluster_name="feedbackhub-dev"
export TF_VAR_cluster_region="us-east-1"
terraform plan
```

## 📊 Module Dependencies

```
network → eks → eks_oidc → irsa_alb_controller → alb_controller
```

Each module depends on outputs from previous modules.

## 🧹 Cleanup

To destroy resources in reverse order:
```bash
# Destroy ALB Controller
cd terraform/eks/alb_controller
terraform destroy

# Destroy IRSA role
cd terraform/iam/irsa_alb_controller
terraform destroy

# Destroy OIDC provider
cd terraform/iam/eks_oidc
terraform destroy

# Destroy EKS cluster
cd terraform/eks
terraform destroy

# Destroy network (last)
cd terraform/network
terraform destroy
```

## 📝 Notes

- All modules use pinned provider versions
- Resources are properly tagged for cost tracking
- Follows AWS Well-Architected Framework principles
- Supports multiple environments through variable overrides
