# Network Module - VPC, Subnets, Gateway, NAT, Security Groups
# This module creates the foundational networking infrastructure for EKS

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for current region
data "aws_region" "current" {}

# Data source for current caller identity
data "aws_caller_identity" "current" {}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name                             = "${var.cluster_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                             = "${var.cluster_name}-public-${count.index + 1}"
    Type                             = "public"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"         = "1"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name                             = "${var.cluster_name}-private-${count.index + 1}"
    Type                             = "private"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# NAT Gateway and EIP resources removed for no-NAT architecture
# This reduces costs and is suitable for development/learning environments
# where nodes can be placed in public subnets

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-public-rt"
    Type = "public"
  })
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Tables for Private Subnets
# No NAT Gateway routes - private subnets are isolated for security
resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  # No default route for private subnets in no-NAT architecture
  # This ensures private subnets remain truly private

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-private-rt-${count.index + 1}"
    Type = "private"
  })
}

# Route Table Associations for Private Subnets
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security Group for EKS Cluster
resource "aws_security_group" "cluster" {
  name_prefix = "${var.cluster_name}-cluster-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS cluster control plane"

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-sg"
    Type = "cluster"
  })
}

# Security Group Rules for EKS Cluster
resource "aws_vpc_security_group_ingress_rule" "cluster_ingress_workstation_https" {
  security_group_id = aws_security_group.cluster.id
  description       = "Allow workstation to communicate with the cluster API Server"

  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.workstation.id
}

resource "aws_vpc_security_group_egress_rule" "cluster_egress_internet" {
  security_group_id = aws_security_group.cluster.id
  description       = "Allow cluster egress access to the Internet"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# Security Group for Node Groups - Hardened for Public Subnet Usage
resource "aws_security_group" "node_group" {
  name_prefix = "${var.cluster_name}-node-group-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS node groups (hardened for public subnets)"

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-group-sg"
    Type = "node-group"
    Note = "Hardened for public subnet usage in no-NAT architecture"
  })
}

# Security Group Rules for Node Groups
resource "aws_vpc_security_group_ingress_rule" "node_group_ingress_self" {
  security_group_id = aws_security_group.node_group.id
  description       = "Allow nodes to communicate with each other"

  referenced_security_group_id = aws_security_group.node_group.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "node_group_ingress_cluster_443" {
  security_group_id = aws_security_group.node_group.id
  description       = "Allow pods to communicate with the cluster API Server"

  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.cluster.id
}

resource "aws_vpc_security_group_ingress_rule" "node_group_ingress_cluster_kubelet" {
  security_group_id = aws_security_group.node_group.id
  description       = "Allow cluster control plane to communicate with worker node kubelet"

  from_port                    = 10250
  to_port                      = 10250
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.cluster.id
}

resource "aws_vpc_security_group_egress_rule" "node_group_egress_internet" {
  security_group_id = aws_security_group.node_group.id
  description       = "Allow nodes egress access to the Internet (required for image pulls and updates)"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# Additional security rule: Restrict SSH access (no SSH allowed from internet for security)
# Uncomment the following rule only if you need SSH access for debugging
# resource "aws_vpc_security_group_ingress_rule" "node_group_ingress_ssh_restricted" {
#   security_group_id = aws_security_group.node_group.id
#   description       = "SSH access from specific CIDR (UNCOMMENT AND RESTRICT AS NEEDED)"
#   
#   from_port   = 22
#   to_port     = 22
#   ip_protocol = "tcp"
#   cidr_ipv4   = "YOUR_IP_CIDR/32"  # Replace with your specific IP
# }

# Security Group for Workstation
resource "aws_security_group" "workstation" {
  name_prefix = "${var.cluster_name}-workstation-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for workstation access to EKS"

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-workstation-sg"
    Type = "workstation"
  })
}

resource "aws_vpc_security_group_egress_rule" "workstation_egress_internet" {
  security_group_id = aws_security_group.workstation.id
  description       = "Allow workstation egress access to the Internet"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${var.cluster_name}-alb-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for Application Load Balancer"

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-alb-sg"
    Type = "alb"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP traffic"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS traffic"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_node_group" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow ALB to communicate with node groups"

  from_port                    = 30000
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.node_group.id
}

# Additional Security Group Rules for ALB to Node Group Communication
resource "aws_vpc_security_group_ingress_rule" "node_group_ingress_alb" {
  security_group_id = aws_security_group.node_group.id
  description       = "Allow ALB to communicate with node groups"

  from_port                    = 30000
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}
