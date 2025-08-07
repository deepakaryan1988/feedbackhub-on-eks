#!/bin/bash

# EKS Health Check Script for FeedbackHub
# Usage: ./scripts/health-check-eks.sh [environment] [namespace]

set -e

# Default values
ENVIRONMENT=${1:-development}
NAMESPACE=${2:-feedbackhub-${ENVIRONMENT}}
SERVICE_NAME="feedbackhub"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏥 FeedbackHub EKS Health Check${NC}"
echo -e "${YELLOW}Environment: $ENVIRONMENT${NC}"
echo -e "${YELLOW}Namespace: $NAMESPACE${NC}"
echo ""

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl not found. Please install kubectl first.${NC}"
        exit 1
    fi
}

# Function to check if namespace exists
check_namespace() {
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        echo -e "${RED}❌ Namespace '$NAMESPACE' not found.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Namespace '$NAMESPACE' exists${NC}"
}

# Function to check deployment status
check_deployment() {
    echo -e "${YELLOW}🔍 Checking deployment status...${NC}"
    
    if kubectl get deployment $SERVICE_NAME -n $NAMESPACE &> /dev/null; then
        kubectl get deployment $SERVICE_NAME -n $NAMESPACE
        
        # Check if deployment is ready
        READY=$(kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
        DESIRED=$(kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.replicas}')
        
        if [ "$READY" = "$DESIRED" ] && [ "$READY" != "" ]; then
            echo -e "${GREEN}✅ Deployment is healthy: $READY/$DESIRED pods ready${NC}"
        else
            echo -e "${YELLOW}⚠️ Deployment not fully ready: $READY/$DESIRED pods ready${NC}"
        fi
    else
        echo -e "${RED}❌ Deployment '$SERVICE_NAME' not found in namespace '$NAMESPACE'${NC}"
        return 1
    fi
}

# Function to check pod status
check_pods() {
    echo -e "${YELLOW}🔍 Checking pod status...${NC}"
    kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME
    
    # Get pod logs for debugging
    echo -e "${YELLOW}📋 Recent pod logs:${NC}"
    kubectl logs -n $NAMESPACE -l app=$SERVICE_NAME --tail=10 || echo "No logs available"
}

# Function to check service status
check_service() {
    echo -e "${YELLOW}🔍 Checking service status...${NC}"
    
    if kubectl get service $SERVICE_NAME -n $NAMESPACE &> /dev/null; then
        kubectl get service $SERVICE_NAME -n $NAMESPACE
        echo -e "${GREEN}✅ Service '$SERVICE_NAME' exists${NC}"
    else
        echo -e "${RED}❌ Service '$SERVICE_NAME' not found in namespace '$NAMESPACE'${NC}"
        return 1
    fi
}

# Function to check ingress status
check_ingress() {
    echo -e "${YELLOW}🔍 Checking ingress status...${NC}"
    
    if kubectl get ingress $SERVICE_NAME -n $NAMESPACE &> /dev/null; then
        kubectl get ingress $SERVICE_NAME -n $NAMESPACE
        echo -e "${GREEN}✅ Ingress '$SERVICE_NAME' exists${NC}"
    else
        echo -e "${YELLOW}⚠️ Ingress '$SERVICE_NAME' not found in namespace '$NAMESPACE'${NC}"
    fi
}

# Function to test health endpoint
test_health_endpoint() {
    echo -e "${YELLOW}🔍 Testing health endpoint...${NC}"
    
    # Port forward and test health endpoint
    kubectl port-forward svc/$SERVICE_NAME 8080:3000 -n $NAMESPACE &
    PORT_FORWARD_PID=$!
    
    # Wait for port forward to be ready
    sleep 3
    
    # Test health endpoint
    if curl -s http://localhost:8080/api/health > /tmp/health_check.json 2>/dev/null; then
        echo -e "${GREEN}✅ Health endpoint responding${NC}"
        echo -e "${BLUE}Health response:${NC}"
        cat /tmp/health_check.json | jq '.' 2>/dev/null || cat /tmp/health_check.json
    else
        echo -e "${RED}❌ Health endpoint not responding${NC}"
    fi
    
    # Clean up port forward
    kill $PORT_FORWARD_PID 2>/dev/null || true
    rm -f /tmp/health_check.json
}

# Function to check resource usage
check_resources() {
    echo -e "${YELLOW}🔍 Checking resource usage...${NC}"
    
    # Get resource requests and limits
    kubectl describe deployment $SERVICE_NAME -n $NAMESPACE | grep -A 10 "Requests:" || echo "No resource requests set"
    
    # Get actual resource usage (if metrics-server is available)
    if kubectl top pods -n $NAMESPACE &> /dev/null; then
        kubectl top pods -n $NAMESPACE -l app=$SERVICE_NAME
    else
        echo -e "${YELLOW}⚠️ Metrics server not available. Cannot show resource usage.${NC}"
    fi
}

# Main execution
main() {
    check_kubectl
    check_namespace
    
    echo ""
    check_deployment
    
    echo ""
    check_pods
    
    echo ""
    check_service
    
    echo ""
    check_ingress
    
    echo ""
    check_resources
    
    echo ""
    test_health_endpoint
    
    echo ""
    echo -e "${GREEN}🎉 Health check completed!${NC}"
    echo ""
    echo -e "${BLUE}📋 Quick commands:${NC}"
    echo "• Check pods: kubectl get pods -n $NAMESPACE"
    echo "• View logs: kubectl logs -f deployment/$SERVICE_NAME -n $NAMESPACE"
    echo "• Port forward: kubectl port-forward svc/$SERVICE_NAME 3000:3000 -n $NAMESPACE"
    echo "• Scale deployment: kubectl scale deployment/$SERVICE_NAME --replicas=3 -n $NAMESPACE"
}

# Run main function
main "$@"
