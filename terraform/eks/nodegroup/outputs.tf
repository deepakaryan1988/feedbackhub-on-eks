# Outputs for EKS Node Groups Module

output "node_groups" {
  description = "Map of node group configurations and attributes"
  value = {
    for k, v in aws_eks_node_group.main : k => {
      arn             = v.arn
      status          = v.status
      capacity_type   = v.capacity_type
      instance_types  = v.instance_types
      ami_type        = v.ami_type
      release_version = v.release_version
      version         = v.version

      scaling_config = v.scaling_config
      update_config  = v.update_config

      remote_access = v.remote_access

      labels = v.labels
      taints = v.taint

      resources = v.resources
    }
  }
}

output "node_group_role_arn" {
  description = "IAM role ARN for the node groups"
  value       = aws_iam_role.node_group.arn
}

output "node_group_role_name" {
  description = "IAM role name for the node groups"
  value       = aws_iam_role.node_group.name
}

output "launch_templates" {
  description = "Map of launch template configurations"
  value = {
    for k, v in aws_launch_template.node_group : k => {
      id             = v.id
      arn            = v.arn
      name           = v.name
      latest_version = v.latest_version
    }
  }
}

output "node_group_names" {
  description = "List of node group names"
  value       = [for k, v in aws_eks_node_group.main : v.node_group_name]
}

output "node_group_arns" {
  description = "List of node group ARNs"
  value       = [for k, v in aws_eks_node_group.main : v.arn]
}

output "node_group_statuses" {
  description = "Map of node group statuses"
  value = {
    for k, v in aws_eks_node_group.main : k => v.status
  }
}
