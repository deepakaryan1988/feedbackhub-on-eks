#!/bin/bash

# Comprehensive Bedrock Integration Test for EKS
echo "🧪 Bedrock Integration Test Suite (EKS)"
echo "========================================"

# EKS ALB URL (update with your actual EKS ALB URL)
ALB_URL="${FEEDBACKHUB_ALB_URL:-http://feedbackhub-eks-alb.ap-south-1.elb.amazonaws.com}"

echo "📋 EKS ALB URL: $ALB_URL"
echo ""

# Step 1: Generate various types of errors
echo "🔍 Step 1: Generating Application Errors..."
echo "----------------------------------------"

# Test 1: 404 Error
echo "📝 Test 1: 404 Error (Non-existent endpoint)"
curl -s -w "\nHTTP Status: %{http_code}\n" "$ALB_URL/non-existent-endpoint" || true

echo ""
echo "⏳ Waiting 5 seconds..."
sleep 5

# Test 2: Invalid JSON Error
echo "📝 Test 2: Invalid JSON Error"
curl -s -w "\nHTTP Status: %{http_code}\n" -X POST "$ALB_URL/api/feedback" \
  -H "Content-Type: application/json" \
  -d '{invalid json}' || true

echo ""
echo "⏳ Waiting 5 seconds..."
sleep 5

# Test 3: Malformed Request Error
echo "📝 Test 3: Malformed Request Error"
curl -s -w "\nHTTP Status: %{http_code}\n" -X POST "$ALB_URL/api/feedback" \
  -H "Content-Type: application/json" \
  -d '{"invalid": "data"}' || true

echo ""
echo "⏳ Waiting 10 seconds for logs to be processed..."
sleep 10

# Step 2: Check CloudWatch Logs for EKS
echo ""
echo "🔍 Step 2: Checking EKS CloudWatch Logs..."
echo "------------------------------------------"
# Update log group name for EKS (will be created by Fluent Bit or AWS for EKS)
aws logs tail /aws/eks/feedbackhub/cluster --since 2m --no-cli-pager || echo "⚠️ EKS log group not found. Check your logging configuration."

echo ""
echo "⏳ Waiting 15 seconds for Lambda processing..."
sleep 15

# Step 3: Check Lambda Logs (same for EKS)
echo ""
echo "🔍 Step 3: Checking Lambda Logs..."
echo "----------------------------------"
aws logs tail /aws/lambda/feedbackhub-eks-bedrock-log-summarizer --since 2m --no-cli-pager

# Step 4: Check S3 Bucket (same for EKS)
echo ""
echo "🔍 Step 4: Checking S3 Bucket..."
echo "--------------------------------"
aws s3 ls s3://feedbackhub-eks-lambda-summaries/log-summaries/ --recursive --no-cli-pager

# Step 5: Get latest summary
echo ""
echo "🔍 Step 5: Latest Summary Content..."
echo "------------------------------------"
LATEST_FILE=$(aws s3 ls s3://feedbackhub-eks-lambda-summaries/log-summaries/ --recursive --no-cli-pager | tail -1 | awk '{print $4}')
if [ ! -z "$LATEST_FILE" ]; then
    echo "📄 Latest summary file: $LATEST_FILE"
    aws s3 cp "s3://feedbackhub-eks-lambda-summaries/$LATEST_FILE" /tmp/latest_summary.json --no-cli-pager
    cat /tmp/latest_summary.json | jq '.' 2>/dev/null || cat /tmp/latest_summary.json
else
    echo "❌ No summary files found"
fi

echo ""
echo "✅ Test Complete!"
echo ""
echo "📸 Screenshot Suggestions:"
echo "1. CloudWatch Logs Console: /aws/eks/feedbackhub/cluster"
echo "2. Lambda Function Console: /aws/lambda/feedbackhub-eks-bedrock-log-summarizer"
echo "3. S3 Console: feedbackhub-eks-lambda-summaries bucket"
echo "4. EKS Cluster Console: AWS EKS Clusters"
echo "5. AWS CLI Output (above) showing the complete flow" 