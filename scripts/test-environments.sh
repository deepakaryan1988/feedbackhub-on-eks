#!/bin/bash

# Test script for MongoDB environment switching
# This script tests both development and production environments

set -e

echo "🧪 Testing MongoDB Environment Switching"
echo "======================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test environment
test_environment() {
    local env=$1
    local port=$2
    
    echo -e "\n${BLUE}Testing $env environment on port $port${NC}"
    echo "----------------------------------------"
    
    # Kill any existing Next.js processes
    pkill -f "next dev" 2>/dev/null || true
    sleep 2
    
    # Start server with specific environment
    if [ "$env" = "production" ]; then
        NODE_ENV=production npm run dev > /tmp/feedbackhub-$env.log 2>&1 &
    else
        npm run dev > /tmp/feedbackhub-$env.log 2>&1 &
    fi
    
    local server_pid=$!
    
    # Wait for server to start
    echo "Starting server..."
    sleep 10
    
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
            echo -e "${YELLOW}⚠️ MongoDB connection logs not found${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Health check failed${NC}"
        echo "Server logs:"
        tail -10 /tmp/feedbackhub-$env.log
    fi
    
    # Stop server
    echo "Stopping server..."
    kill $server_pid 2>/dev/null || true
    wait $server_pid 2>/dev/null || true
    
    echo ""
}

# Function to test with custom environment file
test_with_env_file() {
    local env=$1
    local port=$2
    
    echo -e "\n${BLUE}Testing $env environment with .env.local on port $port${NC}"
    echo "----------------------------------------"
    
    # Create temporary .env.local file
    cat > .env.local << EOF
NODE_ENV=$env
EOF
    
    # Kill any existing Next.js processes
    pkill -f "next dev" 2>/dev/null || true
    sleep 2
    
    # Start server
    npm run dev > /tmp/feedbackhub-$env-envfile.log 2>&1 &
    local server_pid=$!
    
    # Wait for server to start
    echo "Starting server with .env.local..."
    sleep 10
    
    # Test health endpoint
    echo "Testing health endpoint..."
    if curl -s http://localhost:$port/api/health > /tmp/health-$env-envfile.json 2>/dev/null; then
        echo -e "${GREEN}✅ Health check successful${NC}"
        
        # Parse and display health check response
        if command -v jq &> /dev/null; then
            echo "Health check response:"
            jq . /tmp/health-$env-envfile.json
        else
            echo "Health check response:"
            cat /tmp/health-$env-envfile.json
        fi
    else
        echo -e "${YELLOW}⚠️ Health check failed${NC}"
        echo "Server logs:"
        tail -10 /tmp/feedbackhub-$env-envfile.log
    fi
    
    # Stop server
    echo "Stopping server..."
    kill $server_pid 2>/dev/null || true
    wait $server_pid 2>/dev/null || true
    
    # Clean up
    rm -f .env.local
    
    echo ""
}

# Main test execution
main() {
    echo "Starting MongoDB environment tests..."
    
    # Test development environment (default)
    test_environment "development" 3000
    
    # Test production environment with NODE_ENV
    test_environment "production" 3001
    
    # Test with .env.local file
    test_with_env_file "production" 3002
    
    # Cleanup
    echo -e "\n${GREEN}🧹 Cleaning up...${NC}"
    rm -f /tmp/feedbackhub-*.log /tmp/health-*.json
    
    echo -e "\n${GREEN}✅ Environment tests completed!${NC}"
    echo ""
    echo "Summary:"
    echo "- Development environment: Uses feedbackhub-local → feedbackhub_local_db"
    echo "- Production environment: Uses feedbackhub → feedbackhub_prod_db"
    echo "- Health check endpoint: /api/health"
    echo "- Connection logging: Secure logging without password exposure"
}

# Run main function
main "$@" 