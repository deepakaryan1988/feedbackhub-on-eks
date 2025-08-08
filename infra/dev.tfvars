region             = "us-east-1"
environment        = "dev"

# Cost awareness
enable_nat_gateway = false
create_alb         = false
create_ingress     = false

# EKS node sizing
eks_node_instance_type = "t3.small"
eks_node_min_size      = 1
eks_node_desired_size  = 1
eks_node_max_size      = 2
