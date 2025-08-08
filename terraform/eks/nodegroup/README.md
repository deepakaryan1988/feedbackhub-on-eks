# EKS Node Groups Module

This Terraform module creates and manages EKS managed node groups with optimized configurations for production workloads.

## Features

- **Managed Node Groups**: Creates EKS managed node groups with auto-scaling capabilities
- **Custom Launch Templates**: Optimized launch templates with security and performance enhancements
- **Multiple Instance Types**: Support for multiple instance types per node group
- **Flexible Scaling**: Configurable min/max/desired instance counts
- **Security Hardened**: Encrypted EBS volumes, IMDSv2, and security group integration
- **Monitoring**: CloudWatch agent and container insights integration
- **Custom User Data**: Optimized bootstrap script for container workloads

## Usage

```hcl
module "node_groups" {
  source = "./terraform/nodegroups"

  cluster_name                        = "my-eks-cluster"
  cluster_version                     = "1.28"
  cluster_endpoint                    = module.cluster.cluster_endpoint
  cluster_certificate_authority_data  = module.cluster.cluster_certificate_authority_data
  private_subnet_ids                  = module.network.private_subnet_ids
  node_security_group_id              = module.cluster.node_security_group_id

  node_groups = {
    # General purpose nodes
    general = {
      instance_types = ["t3.medium", "t3.large"]
      desired_size   = 2
      max_size       = 6
      min_size       = 1
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      k8s_labels = {
        role = "general"
      }
    }

    # Spot instances for cost optimization
    spot = {
      instance_types = ["t3.medium", "t3.large", "t3.xlarge"]
      desired_size   = 2
      max_size       = 10
      min_size       = 0
      capacity_type  = "SPOT"
      disk_size      = 50
      k8s_labels = {
        role = "spot"
      }
      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }

    # Compute optimized nodes
    compute = {
      instance_types = ["c5.large", "c5.xlarge"]
      desired_size   = 0
      max_size       = 5
      min_size       = 0
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
      k8s_labels = {
        role = "compute"
      }
      taints = [{
        key    = "compute"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  tags = {
    Environment = "production"
    Project     = "feedbackhub"
  }
}
```

## Node Group Configuration

### Instance Configuration
- `instance_types`: List of EC2 instance types (supports mixed instance types)
- `ami_type`: Amazon Linux 2 (AL2_x86_64) or Bottlerocket (BOTTLEROCKET_x86_64)
- `ami_id`: Custom AMI ID (optional, uses latest EKS optimized AMI by default)
- `capacity_type`: ON_DEMAND or SPOT
- `disk_size`: EBS volume size in GB (default: 50)

### Scaling Configuration
- `desired_size`: Desired number of nodes
- `max_size`: Maximum number of nodes
- `min_size`: Minimum number of nodes
- `max_unavailable_percentage`: Maximum percentage of nodes unavailable during updates

### Kubernetes Configuration
- `k8s_labels`: Kubernetes labels applied to nodes
- `taints`: Kubernetes taints applied to nodes
- `bootstrap_extra_args`: Additional arguments for EKS bootstrap script

### Access Configuration
- `key_name`: EC2 key pair for SSH access (optional)

## Security Features

### Launch Template Security
- **Encrypted EBS Volumes**: All volumes encrypted at rest
- **IMDSv2 Enforcement**: Instance metadata service v2 required
- **Security Groups**: Proper security group configuration
- **Monitoring**: CloudWatch detailed monitoring enabled

### IAM Permissions
- Minimal required permissions for EKS worker nodes
- Additional CloudWatch and logging permissions
- SSM Session Manager access for secure remote access

### Network Security
- Nodes deployed in private subnets only
- Security group rules for cluster communication
- Optional SSH access through bastion hosts

## Monitoring and Logging

### CloudWatch Integration
- Container Insights enabled
- Custom metrics and logs
- Performance monitoring

### Log Management
- Docker log rotation configured
- CloudWatch log shipping
- Structured logging support

## Outputs

| Name | Description |
|------|-------------|
| `node_groups` | Complete node group configurations and status |
| `node_group_role_arn` | IAM role ARN for node groups |
| `node_group_role_name` | IAM role name for node groups |
| `launch_templates` | Launch template details |
| `node_group_names` | List of node group names |
| `node_group_arns` | List of node group ARNs |
| `node_group_statuses` | Map of node group statuses |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Best Practices

### Instance Selection
- Use `t3.medium` or larger for general workloads
- Consider `c5` instances for CPU-intensive workloads
- Use `r5` instances for memory-intensive workloads
- Mix ON_DEMAND and SPOT instances for cost optimization

### Scaling Strategy
- Set appropriate min/max values based on workload patterns
- Use Cluster Autoscaler for automatic scaling
- Consider Vertical Pod Autoscaler for right-sizing

### Cost Optimization
- Use SPOT instances for fault-tolerant workloads
- Implement proper taints and tolerations
- Monitor and right-size instances regularly

### Security
- Always use encrypted EBS volumes
- Enable Session Manager instead of SSH access
- Regularly update AMIs for security patches
- Use least privilege IAM policies

## Troubleshooting

### Node Group Creation Issues
- Check IAM permissions for EKS service
- Verify subnet and security group configurations
- Ensure cluster is in ACTIVE state

### Node Join Issues
- Check user data script execution
- Verify cluster endpoint accessibility
- Check security group rules

### Scaling Issues
- Monitor Cluster Autoscaler logs
- Check node group capacity and limits
- Verify resource requests and limits

## References

- [EKS Managed Node Groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)
- [EKS Optimized AMIs](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html)
- [Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
