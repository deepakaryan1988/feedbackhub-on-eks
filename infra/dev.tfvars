region      = "us-east-1"
environment = "dev"

# Cost awareness
enable_nat_gateway = false
create_alb         = false
create_ingress     = false

# Scope down to 2 AZs to reduce resources
availability_zones_count   = 2
cloudwatch_log_retention_days = 7
enable_cloudwatch_logging  = false

# EKS node sizing
eks_node_instance_type = "t3.small"
eks_node_min_size      = 1
eks_node_desired_size  = 1
eks_node_max_size      = 2
