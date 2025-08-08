#!/bin/bash

# EKS Node User Data Script
# This script bootstraps EKS worker nodes with additional configuration

set -e

# Variables from template
CLUSTER_NAME="${cluster_name}"
CLUSTER_ENDPOINT="${cluster_endpoint}"
CLUSTER_CA_DATA="${cluster_ca_data}"
BOOTSTRAP_ARGUMENTS="${bootstrap_arguments}"

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting EKS node bootstrap process..."
echo "Cluster Name: $CLUSTER_NAME"
echo "Bootstrap Arguments: $BOOTSTRAP_ARGUMENTS"

# Update system packages
yum update -y

# Install additional packages
yum install -y \
    awscli \
    amazon-ssm-agent \
    htop \
    jq \
    wget \
    curl \
    unzip

# Start and enable SSM agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Configure CloudWatch agent for container insights
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c ssm:AmazonCloudWatch-EKS-ContainerInsights

# Set up log rotation for container logs
cat <<EOF > /etc/logrotate.d/docker-containers
/var/lib/docker/containers/*/*.log {
    rotate 5
    daily
    compress
    missingok
    delaycompress
    copytruncate
}
EOF

# Optimize kernel parameters for container workloads
cat <<EOF >> /etc/sysctl.conf
# Container optimizations
net.core.somaxconn = 65535
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.core.netdev_max_backlog = 4000
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_max_syn_backlog = 20480
net.ipv4.tcp_max_tw_buckets = 400000
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_wmem = 4096 65536 16777216
vm.min_free_kbytes = 65536
vm.overcommit_memory = 1
kernel.panic = 10
kernel.panic_on_oops = 1
EOF

sysctl -p

# Set up container runtime optimizations
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "5"
    },
    "live-restore": true,
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 5,
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ]
}
EOF

# Bootstrap the node to join the EKS cluster
echo "Bootstrapping node to join EKS cluster..."
/etc/eks/bootstrap.sh $CLUSTER_NAME $BOOTSTRAP_ARGUMENTS

echo "EKS node bootstrap completed successfully"

# Signal completion (useful for Auto Scaling Groups)
# Note: In EKS managed node groups, CloudFormation signals are not needed
# /opt/aws/bin/cfn-signal -e $? --stack StackName --resource NodeGroup --region Region || true

# Create a marker file to indicate successful bootstrap
echo "$(date): EKS node bootstrap completed" > /opt/eks-bootstrap-complete
