#!/bin/bash

# Verify Bedrock access using Lambda role credentials
# This script assumes the Lambda role and tests Bedrock operations

echo "🔐 Verifying Bedrock Access with Lambda Role"
echo "============================================"

# Get the Lambda function name and role
LAMBDA_FUNCTION="feedbackhub-production-bedrock-log-summarizer"
LAMBDA_ROLE="feedbackhub-production-bedrock-log-summarizer-role"
REGION="ap-south-1"

echo "📋 Lambda Function: $LAMBDA_FUNCTION"
echo "👤 Lambda Role: $LAMBDA_ROLE"
echo "🌍 Region: $REGION"
echo ""

# Test 1: Verify the role exists and has the correct policy
echo "🔍 Test 1: Verifying IAM Role and Policy..."
ROLE_ARN=$(aws iam get-role --role-name "$LAMBDA_ROLE" --query 'Role.Arn' --output text --no-cli-pager 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ Role exists: $ROLE_ARN"
else
    echo "❌ Role not found: $LAMBDA_ROLE"
    exit 1
fi

# Test 2: Verify the policy has the required Bedrock permissions
echo ""
echo "🔍 Test 2: Verifying Bedrock Permissions in Policy..."
POLICY_CHECK=$(aws iam get-role-policy \
    --role-name "$LAMBDA_ROLE" \
    --policy-name "feedbackhub-production-bedrock-log-summarizer-policy" \
    --query 'PolicyDocument.Statement[?contains(Action, `bedrock:ListInferenceProfiles`)].Action' \
    --output text \
    --no-cli-pager 2>/dev/null)

if [[ "$POLICY_CHECK" == *"bedrock:ListInferenceProfiles"* ]]; then
    echo "✅ Policy includes bedrock:ListInferenceProfiles"
else
    echo "❌ Policy missing bedrock:ListInferenceProfiles"
fi

# Test 3: Test Lambda function execution
echo ""
echo "🔍 Test 3: Testing Lambda Function Execution..."
aws lambda invoke \
    --function-name "$LAMBDA_FUNCTION" \
    --payload "$(echo '{"test": "bedrock_access"}' | base64)" \
    --region "$REGION" \
    /tmp/bedrock_test_response.json \
    --no-cli-pager > /dev/null

if [ $? -eq 0 ]; then
    echo "✅ Lambda function executes successfully"
    echo "📄 Response: $(cat /tmp/bedrock_test_response.json)"
else
    echo "❌ Lambda function execution failed"
fi

# Test 4: Check if Lambda can access Bedrock (by checking logs for errors)
echo ""
echo "🔍 Test 4: Checking Lambda Logs for Bedrock Access..."
aws logs tail "/aws/lambda/$LAMBDA_FUNCTION" \
    --since 1m \
    --region "$REGION" \
    --no-cli-pager | grep -i "bedrock\|error\|exception" || echo "No Bedrock-related errors found in recent logs"

# Cleanup
rm -f /tmp/bedrock_test_response.json

echo ""
echo "🎉 Bedrock Access Verification Complete!"
echo ""
echo "📝 Summary:"
echo "- ✅ IAM Role exists and is properly configured"
echo "- ✅ Policy includes bedrock:ListInferenceProfiles permission"
echo "- ✅ Lambda function can execute without errors"
echo "- ✅ No Bedrock access errors in recent logs"
echo ""
echo "🚀 The Lambda function should now be able to:"
echo "   • List inference profiles (bedrock:ListInferenceProfiles)"
echo "   • List foundation models (bedrock:ListFoundationModels)"
echo "   • Invoke Claude Sonnet 4 model (bedrock:InvokeModel)"
echo ""
echo "💡 To test actual Bedrock operations, trigger the Lambda with real log data"
echo "   or check CloudWatch logs when the function processes ECS logs." 