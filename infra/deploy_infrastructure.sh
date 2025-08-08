#!/bin/bash

# Phased Infrastructure Deployment Script
# Cloud Architect approach for reliable EKS deployment

set -e

echo "🏗️ Starting phased infrastructure deployment for feedbackhub-dev..."

# Phase 1: Network Infrastructure
echo ""
echo "📋 Phase 1: Deploying Network Infrastructure..."
terraform apply -var-file="terraform.tfvars.dev" \
  -target=module.network \
  -auto-approve

echo "✅ Network infrastructure deployed successfully"

# Phase 2: EKS Cluster
echo ""
echo "📋 Phase 2: Deploying EKS Cluster..."
terraform apply -var-file="terraform.tfvars.dev" \
  -target=module.eks_cluster \
  -auto-approve

echo "✅ EKS cluster deployed successfully"

# Wait for cluster to be ready
echo ""
echo "⏳ Waiting for EKS cluster to be ready..."
aws eks wait cluster-active --name feedbackhub-dev --region us-east-1
echo "✅ EKS cluster is now active"

# Phase 3: Node Groups
echo ""
echo "📋 Phase 3: Deploying Node Groups..."
terraform apply -var-file="terraform.tfvars.dev" \
  -target=module.eks_nodegroups \
  -auto-approve

echo "✅ Node groups deployed successfully"

# Wait for node groups to be ready
echo ""
echo "⏳ Waiting for node groups to be ready..."
for nodegroup in $(aws eks list-nodegroups --cluster-name feedbackhub-dev --region us-east-1 --query 'nodegroups[]' --output text); do
  echo "  Waiting for node group: $nodegroup"
  aws eks wait nodegroup-active --cluster-name feedbackhub-dev --nodegroup-name $nodegroup --region us-east-1
done
echo "✅ All node groups are now active"

# Phase 4: Supporting Infrastructure
echo ""
echo "📋 Phase 4: Deploying Supporting Infrastructure..."
terraform apply -var-file="terraform.tfvars.dev" \
  -target=module.alb_controller \
  -target=module.monitoring \
  -target=module.logging \
  -auto-approve

echo "✅ Supporting infrastructure deployed successfully"

# Phase 5: Final Complete Apply
echo ""
echo "📋 Phase 5: Final complete infrastructure apply..."
terraform apply -var-file="terraform.tfvars.dev" -auto-approve

echo ""
echo "🎉 Complete infrastructure deployment successful!"
echo ""
echo "📋 Next steps:"
echo "  1. Update kubeconfig: aws eks update-kubeconfig --name feedbackhub-dev --region us-east-1"
echo "  2. Verify cluster: kubectl get nodes"
echo "  3. Check monitoring: kubectl get pods -n monitoring"
echo "  4. Check logging: kubectl get pods -n logging"
