region             = "us-east-1"
environment        = "prod"

# Cost toggles (enable as needed)
enable_nat_gateway = true
create_alb         = true
create_ingress     = true

# EKS node sizing
eks_node_instance_type = "t3.medium"
eks_node_min_size      = 2
eks_node_desired_size  = 3
eks_node_max_size      = 6
