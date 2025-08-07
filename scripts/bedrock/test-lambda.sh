#!/bin/bash

# Test Bedrock permissions by invoking the Lambda function
# This will use the Lambda role's permissions to access Bedrock

echo "🧪 Testing Bedrock Permissions via Lambda Function"
echo "=================================================="

LAMBDA_FUNCTION="feedbackhub-production-bedrock-log-summarizer"
REGION="ap-south-1"

echo "📋 Lambda Function: $LAMBDA_FUNCTION"
echo "🌍 Region: $REGION"
echo ""

# Create a test payload that simulates CloudWatch log data
# This will trigger the Lambda to process logs and potentially use Bedrock
echo "🔍 Creating test log data payload..."

# Create a simple log event structure
TEST_PAYLOAD=$(cat <<EOF
{
  "logEvents": [
    {
      "timestamp": $(date +%s)000,
      "message": "Test log entry for Bedrock summarization - This is a test log message to verify that the Lambda function can access Bedrock services and generate summaries using Claude Sonnet 4."
    },
    {
      "timestamp": $(date +%s)000,
      "message": "Another test log entry - This should trigger the log summarization process and test the Bedrock integration."
    }
  ],
  "logStream": "test-stream",
  "logGroup": "/ecs/feedbackhub"
}
EOF
)

echo "📄 Test Payload:"
echo "$TEST_PAYLOAD" | jq '.'
echo ""

# Invoke the Lambda function
echo "🚀 Invoking Lambda function..."
aws lambda invoke \
    --function-name "$LAMBDA_FUNCTION" \
    --payload "$(echo "$TEST_PAYLOAD" | base64)" \
    --region "$REGION" \
    /tmp/lambda_bedrock_test.json \
    --no-cli-pager

if [ $? -eq 0 ]; then
    echo "✅ Lambda invocation successful"
    echo "📄 Response:"
    cat /tmp/lambda_bedrock_test.json | jq '.'
    echo ""
else
    echo "❌ Lambda invocation failed"
    exit 1
fi

# Check Lambda logs for Bedrock operations
echo "🔍 Checking Lambda logs for Bedrock operations..."
aws logs tail "/aws/lambda/$LAMBDA_FUNCTION" \
    --since 2m \
    --region "$REGION" \
    --no-cli-pager

# Cleanup
rm -f /tmp/lambda_bedrock_test.json

echo ""
echo "🎉 Bedrock Lambda Test Complete!"
echo ""
echo "💡 If you see any Bedrock-related errors in the logs,"
echo "   it means the Lambda function tried to access Bedrock"
echo "   and either succeeded or failed due to permissions." 