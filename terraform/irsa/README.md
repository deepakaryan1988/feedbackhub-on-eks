# IAM Roles for Service Accounts (IRSA) Module

This Terraform module creates IAM roles that can be assumed by Kubernetes service accounts using the IAM Roles for Service Accounts (IRSA) feature in Amazon EKS.

## Features

- **Custom IRSA Roles**: Create any number of custom IAM roles for your applications
- **Pre-configured Common Roles**: Ready-to-use roles for ALB Ingress Controller, EBS CSI Driver, and External DNS
- **Flexible Policy Attachments**: Support for both managed and inline policies
- **Security Best Practices**: Least privilege access with proper assume role conditions
- **Service Account Annotations**: Convenience outputs for Kubernetes service account annotations

## Usage

### Basic Usage

```hcl
module "irsa" {
  source = "./terraform/irsa"

  cluster_name      = "my-eks-cluster"
  oidc_provider_arn = module.cluster.oidc_provider_arn
  oidc_issuer       = module.cluster.oidc_issuer

  # Create common roles
  create_alb_controller_role = true
  create_ebs_csi_role       = true
  create_external_dns_role  = false

  tags = {
    Environment = "production"
    Project     = "feedbackhub"
  }
}
```

### Custom IRSA Roles

```hcl
module "irsa" {
  source = "./terraform/irsa"

  cluster_name      = "my-eks-cluster"
  oidc_provider_arn = module.cluster.oidc_provider_arn
  oidc_issuer       = module.cluster.oidc_issuer

  irsa_roles = {
    # Application role with S3 access
    feedbackhub_app = {
      namespace            = "default"
      service_account_name = "feedbackhub-sa"
      managed_policy_arns  = [
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
      ]
      inline_policies = {
        s3_write = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = [
                "s3:PutObject",
                "s3:DeleteObject"
              ]
              Resource = [
                "arn:aws:s3:::my-feedbackhub-bucket/*"
              ]
            }
          ]
        })
      }
    }

    # Monitoring role
    prometheus = {
      namespace            = "monitoring"
      service_account_name = "prometheus-server"
      inline_policies = {
        cloudwatch = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = [
                "cloudwatch:GetMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics"
              ]
              Resource = "*"
            }
          ]
        })
      }
    }

    # Backup role with additional conditions
    backup_service = {
      namespace            = "backup"
      service_account_name = "backup-sa"
      max_session_duration = 7200  # 2 hours
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForBackup"
      ]
      additional_conditions = {
        "StringLike" = {
          "aws:RequestedRegion" = "us-east-*"
        }
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "feedbackhub"
  }
}
```

## Common Roles

### ALB Ingress Controller

The ALB Ingress Controller role provides the necessary permissions to:
- Create and manage Application Load Balancers
- Manage target groups and listeners
- Create and manage security groups
- Integrate with AWS WAF and AWS Shield

### EBS CSI Driver

The EBS CSI Driver role provides permissions to:
- Create, attach, and manage EBS volumes
- Take snapshots of EBS volumes
- Manage volume lifecycle

### External DNS

The External DNS role provides permissions to:
- Manage Route 53 hosted zones
- Create and update DNS records
- List hosted zones and record sets

## Service Account Configuration

After creating IRSA roles, you need to annotate your Kubernetes service accounts:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: feedbackhub-sa
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/my-cluster-feedbackhub_app-irsa
```

You can use the module outputs to get the correct annotations:

```hcl
# In your Kubernetes manifests
resource "kubernetes_service_account" "feedbackhub" {
  metadata {
    name      = "feedbackhub-sa"
    namespace = "default"
    annotations = module.irsa.service_account_annotations.feedbackhub_app
  }
}
```

## Role Configuration

### Basic Configuration
- `namespace`: Kubernetes namespace where the service account exists
- `service_account_name`: Name of the Kubernetes service account
- `max_session_duration`: Maximum session duration in seconds (default: 3600)

### Policy Attachments
- `managed_policy_arns`: List of AWS managed policy ARNs to attach
- `inline_policies`: Map of inline policy names to policy documents

### Security Controls
- `additional_conditions`: Extra conditions for the assume role policy (optional)

## Security Best Practices

### Principle of Least Privilege
- Only grant the minimum permissions required for your application
- Use specific resource ARNs instead of wildcards where possible
- Regularly review and audit IRSA role permissions

### Condition-Based Access
- Use condition blocks to restrict role usage
- Consider adding conditions for:
  - Time-based access
  - Source IP restrictions
  - MFA requirements
  - Regional restrictions

### Example Security Conditions

```hcl
irsa_roles = {
  secure_app = {
    namespace            = "production"
    service_account_name = "secure-app-sa"
    additional_conditions = {
      "StringEquals" = {
        "aws:RequestedRegion" = "us-east-1"
      }
      "DateGreaterThan" = {
        "aws:CurrentTime" = "2024-01-01T00:00:00Z"
      }
      "IpAddress" = {
        "aws:SourceIp" = ["10.0.0.0/8", "172.16.0.0/12"]
      }
    }
  }
}
```

## Monitoring and Troubleshooting

### CloudTrail Integration
- Monitor IRSA role usage through CloudTrail
- Set up alerts for unusual AssumeRoleWithWebIdentity calls
- Track policy changes and role modifications

### Common Issues

#### Role Assumption Failures
1. **OIDC Provider Configuration**: Verify OIDC provider is correctly configured
2. **Service Account Annotation**: Ensure service account has correct role ARN annotation
3. **Namespace/Name Mismatch**: Verify namespace and service account name match role conditions
4. **Trust Policy**: Check assume role policy conditions

#### Permission Denied Errors
1. **Policy Attachment**: Verify correct policies are attached to the role
2. **Resource ARNs**: Check if resource ARNs in policies are correct
3. **Condition Blocks**: Review condition blocks for overly restrictive conditions

### Debugging Commands

```bash
# Check service account annotations
kubectl get serviceaccount -n <namespace> <sa-name> -o yaml

# Check pod's projected service account token
kubectl exec -it <pod-name> -- cat /var/run/secrets/eks.amazonaws.com/serviceaccount/token

# Describe role to see policies
aws iam get-role --role-name <role-name>
aws iam list-attached-role-policies --role-name <role-name>
aws iam list-role-policies --role-name <role-name>
```

## Outputs

| Name | Description |
|------|-------------|
| `irsa_roles` | Map of custom IRSA roles with names and ARNs |
| `alb_controller_role_arn` | ARN of ALB Ingress Controller role |
| `alb_controller_role_name` | Name of ALB Ingress Controller role |
| `ebs_csi_driver_role_arn` | ARN of EBS CSI Driver role |
| `ebs_csi_driver_role_name` | Name of EBS CSI Driver role |
| `external_dns_role_arn` | ARN of External DNS role |
| `external_dns_role_name` | Name of External DNS role |
| `service_account_annotations` | Service account annotations for all roles |
| `all_role_arns` | List of all created role ARNs |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Examples

See the [examples](./examples/) directory for complete working examples:
- [Basic IRSA setup](./examples/basic/)
- [Multi-application setup](./examples/multi-app/)
- [Advanced security configurations](./examples/advanced-security/)

## References

- [IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [ALB Ingress Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [EBS CSI Driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)
- [External DNS](https://github.com/kubernetes-sigs/external-dns)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
