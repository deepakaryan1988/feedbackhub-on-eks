#!/bin/bash

# Import script for existing AWS resources
# This script systematically imports existing AWS resources into Terraform state

set -e

echo "🏗️ Starting systematic resource import for feedbackhub-dev infrastructure..."

# Set cluster name
CLUSTER_NAME="feedbackhub-dev"
REGION="us-east-1"

# Function to check if resource exists in state
check_state_resource() {
    local resource_address="$1"
    if terraform state show "$resource_address" >/dev/null 2>&1; then
        echo "✅ Resource $resource_address already in state"
        return 0
    else
        echo "❌ Resource $resource_address not in state"
        return 1
    fi
}

# Function to import resource safely
import_resource() {
    local resource_address="$1"
    local resource_id="$2"
    
    echo "🔄 Importing $resource_address with ID: $resource_id"
    
    if check_state_resource "$resource_address"; then
        echo "⏭️ Skipping import for $resource_address (already exists)"
        return 0
    fi
    
    if terraform import "$resource_address" "$resource_id"; then
        echo "✅ Successfully imported $resource_address"
        return 0
    else
        echo "❌ Failed to import $resource_address"
        return 1
    fi
}

echo "📋 Step 1: Getting existing resource IDs from AWS..."

# Get KMS key ID for alias/feedbackhub-dev-eks
echo "🔍 Looking for KMS alias: alias/$CLUSTER_NAME-eks"
KMS_ALIAS_KEY_ID=$(aws kms describe-key --key-id "alias/$CLUSTER_NAME-eks" --query 'KeyMetadata.KeyId' --output text 2>/dev/null || echo "")

if [ -n "$KMS_ALIAS_KEY_ID" ]; then
    echo "✅ Found KMS key: $KMS_ALIAS_KEY_ID"
else
    echo "❌ KMS alias alias/$CLUSTER_NAME-eks not found"
fi

# Check for EKS KMS key from module
echo "🔍 Looking for EKS module KMS alias: alias/eks/$CLUSTER_NAME"
EKS_MODULE_KMS_ALIAS=$(aws kms list-aliases --query "Aliases[?AliasName=='alias/eks/$CLUSTER_NAME'].TargetKeyId" --output text 2>/dev/null || echo "")

if [ -n "$EKS_MODULE_KMS_ALIAS" ]; then
    echo "✅ Found EKS module KMS key: $EKS_MODULE_KMS_ALIAS"
else
    echo "❌ EKS module KMS alias not found"
fi

# Check for CloudWatch log group
echo "🔍 Looking for CloudWatch log group: /aws/eks/$CLUSTER_NAME/cluster"
LOG_GROUP_EXISTS=$(aws logs describe-log-groups --log-group-name-prefix "/aws/eks/$CLUSTER_NAME/cluster" --query 'logGroups[0].logGroupName' --output text 2>/dev/null || echo "None")

if [ "$LOG_GROUP_EXISTS" != "None" ]; then
    echo "✅ Found CloudWatch log group: $LOG_GROUP_EXISTS"
else
    echo "❌ CloudWatch log group not found"
fi

echo ""
echo "📋 Step 2: Planning import strategy..."

# Create a plan to see what needs to be imported
echo "🔍 Running terraform plan to see what conflicts..."
terraform plan -var-file="terraform.tfvars.dev" -detailed-exitcode > /tmp/plan_output.log 2>&1 || PLAN_EXIT_CODE=$?

if [ "$PLAN_EXIT_CODE" = "2" ]; then
    echo "📋 Plan shows changes needed - proceeding with imports"
else
    echo "✅ No changes needed or plan failed"
fi

echo ""
echo "📋 Step 3: Importing conflicting resources..."

# Import KMS key and alias if they exist
if [ -n "$KMS_ALIAS_KEY_ID" ]; then
    echo "🔑 Importing KMS resources..."
    
    # Import the KMS key first
    import_resource "module.eks_cluster.aws_kms_key.eks" "$KMS_ALIAS_KEY_ID"
    
    # Import the KMS alias
    import_resource "module.eks_cluster.aws_kms_alias.eks" "alias/$CLUSTER_NAME-eks"
fi

# Import EKS module KMS alias if it exists
if [ -n "$EKS_MODULE_KMS_ALIAS" ]; then
    echo "🔑 Importing EKS module KMS alias..."
    import_resource "module.eks_cluster.module.eks.module.kms.aws_kms_alias.this[\"cluster\"]" "alias/eks/$CLUSTER_NAME"
fi

# Import CloudWatch log group if it exists
if [ "$LOG_GROUP_EXISTS" != "None" ]; then
    echo "📊 Importing CloudWatch log group..."
    import_resource "module.eks_cluster.module.eks.aws_cloudwatch_log_group.this[0]" "/aws/eks/$CLUSTER_NAME/cluster"
fi

echo ""
echo "📋 Step 4: Running terraform plan again to check for remaining conflicts..."
terraform plan -var-file="terraform.tfvars.dev" -detailed-exitcode || FINAL_PLAN_EXIT_CODE=$?

if [ "$FINAL_PLAN_EXIT_CODE" = "0" ]; then
    echo "✅ No changes needed - all resources are now properly tracked!"
elif [ "$FINAL_PLAN_EXIT_CODE" = "2" ]; then
    echo "📋 Some changes still needed - this is expected for new resources"
else
    echo "❌ Plan failed - check for errors"
    exit 1
fi

echo ""
echo "🎉 Import process completed!"
echo "📋 Next: Review the plan and apply remaining changes with:"
echo "   terraform apply -var-file='terraform.tfvars.dev'"
