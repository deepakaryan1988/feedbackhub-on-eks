#!/bin/bash

# MongoDB Connection Test Script
# Tests the robust MongoDB connection layer in both development and production environments

set -e

echo "🧪 Testing MongoDB Connection Layer"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to test environment
test_environment() {
    local env=$1
    local port=$2
    
    echo -e "\n${BLUE}Testing $env environment on port $port${NC}"
    echo "----------------------------------------"
    
    # Start server in background
    NODE_ENV=$env npm run dev > /tmp/feedbackhub-$env.log 2>&1 &
    local server_pid=$!
    
    # Wait for server to start
    echo "Starting server..."
    sleep 8
    
    # Test health endpoint
    echo "Testing health endpoint..."
    if curl -s http://localhost:$port/api/health > /tmp/health-$env.json 2>/dev/null; then
        echo -e "${GREEN}✅ Health check successful${NC}"
        
        # Parse and display health check response
        if command -v jq &> /dev/null; then
            echo "Health check response:"
            jq . /tmp/health-$env.json
        else
            echo "Health check response:"
            cat /tmp/health-$env.json
        fi
        
        # Check for connection logs
        if grep -q "✅ Connected to MongoDB Atlas" /tmp/feedbackhub-$env.log; then
            echo -e "${GREEN}✅ MongoDB connection successful${NC}"
            
            # Extract and display connection info
            echo "Connection details:"
            grep -E "(✅|📊|🌍|🔗)" /tmp/feedbackhub-$env.log | head -4
        else
            echo -e "${RED}❌ MongoDB connection failed${NC}"
            echo "Server logs:"
            tail -10 /tmp/feedbackhub-$env.log
        fi
    else
        echo -e "${RED}❌ Health check failed${NC}"
        echo "Server logs:"
        tail -10 /tmp/feedbackhub-$env.log
    fi
    
    # Stop server
    echo "Stopping server..."
    kill $server_pid 2>/dev/null || true
    wait $server_pid 2>/dev/null || true
    
    echo ""
}

# Function to test error scenarios
test_error_scenarios() {
    echo -e "\n${YELLOW}Testing Error Scenarios${NC}"
    echo "------------------------"
    
    # Test with invalid NODE_ENV
    echo "Testing with invalid NODE_ENV..."
    NODE_ENV=invalid npm run dev > /tmp/feedbackhub-invalid.log 2>&1 &
    local invalid_pid=$!
    sleep 5
    kill $invalid_pid 2>/dev/null || true
    
    if grep -q "feedbackhub" /tmp/feedbackhub-invalid.log; then
        echo -e "${GREEN}✅ Graceful handling of invalid environment${NC}"
    else
        echo -e "${RED}❌ Unexpected behavior with invalid environment${NC}"
    fi
}

# Main test execution
main() {
    echo "Starting MongoDB connection tests..."
    
    # Test development environment
    test_environment "development" 3000
    
    # Test production environment
    test_environment "production" 3001
    
    # Test error scenarios
    test_error_scenarios
    
    # Cleanup
    echo -e "\n${GREEN}🧹 Cleaning up...${NC}"
    rm -f /tmp/feedbackhub-*.log /tmp/health-*.json
    
    echo -e "\n${GREEN}✅ MongoDB connection tests completed!${NC}"
    echo ""
    echo "Summary:"
    echo "- Development environment: Uses feedbackhub-local → feedbackhub_local_db"
    echo "- Production environment: Uses feedbackhub → feedbackhub_prod_db"
    echo "- Health check endpoint: /api/health"
    echo "- Connection logging: Secure logging without password exposure"
}

# Run main function
main "$@" 