#!/bin/bash

# Development Docker Management Script for FeedbackHub
# This script provides easy commands for local development with Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       Start development environment"
    echo "  stop        Stop development environment"
    echo "  restart     Restart development environment"
    echo "  logs        Show application logs"
    echo "  mongo-logs  Show MongoDB logs"
    echo "  shell       Open shell in app container"
    echo "  mongo-shell Open shell in MongoDB container"
    echo "  clean       Clean up containers and volumes"
    echo "  build       Rebuild development image"
    echo "  status      Show status of services"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start     # Start development environment"
    echo "  $0 logs      # Show application logs"
    echo "  $0 clean     # Clean up everything"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to start development environment
start_dev() {
    print_header "Starting FeedbackHub Development Environment"
    check_docker
    
    print_status "Starting services..."
    docker-compose -f docker/docker-compose.dev.yml up -d
    
    print_status "Waiting for services to be ready..."
    sleep 10
    
    # Check if services are healthy
    if docker-compose -f docker/docker-compose.dev.yml ps | grep -q "healthy"; then
        print_status "Development environment started successfully!"
        print_status "App URL: http://localhost:3000"
        print_status "MongoDB: localhost:27017"
    else
        print_warning "Services started but health checks may still be running..."
        print_status "Check status with: $0 status"
    fi
}

# Function to stop development environment
stop_dev() {
    print_header "Stopping FeedbackHub Development Environment"
    check_docker
    
    print_status "Stopping services..."
    docker-compose -f docker/docker-compose.dev.yml down
    
    print_status "Development environment stopped"
}

# Function to restart development environment
restart_dev() {
    print_header "Restarting FeedbackHub Development Environment"
    stop_dev
    sleep 2
    start_dev
}

# Function to show logs
show_logs() {
    print_header "Application Logs"
    check_docker
    
    docker-compose -f docker/docker-compose.dev.yml logs -f app
}

# Function to show MongoDB logs
show_mongo_logs() {
    print_header "MongoDB Logs"
    check_docker
    
    docker-compose -f docker/docker-compose.dev.yml logs -f mongo
}

# Function to open shell in app container
open_app_shell() {
    print_header "Opening Shell in App Container"
    check_docker
    
    docker-compose -f docker/docker-compose.dev.yml exec app sh
}

# Function to open shell in MongoDB container
open_mongo_shell() {
    print_header "Opening Shell in MongoDB Container"
    check_docker
    
    docker-compose -f docker/docker-compose.dev.yml exec mongo mongosh
}

# Function to clean up
cleanup() {
    print_header "Cleaning Up Development Environment"
    check_docker
    
    print_warning "This will remove all containers, volumes, and images!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Stopping and removing containers..."
        docker-compose -f docker/docker-compose.dev.yml down -v
        
        print_status "Removing development images..."
        docker rmi feedbackhub-on-eks_app 2>/dev/null || true
        
        print_status "Cleanup completed"
    else
        print_status "Cleanup cancelled"
    fi
}

# Function to rebuild development image
rebuild() {
    print_header "Rebuilding Development Image"
    check_docker
    
    print_status "Stopping services..."
    docker-compose -f docker/docker-compose.dev.yml down
    
    print_status "Removing old image..."
    docker rmi feedbackhub-on-eks_app 2>/dev/null || true
    
    print_status "Building new image..."
    docker-compose -f docker/docker-compose.dev.yml build --no-cache
    
    print_status "Starting services with new image..."
    start_dev
}

# Function to show status
show_status() {
    print_header "Service Status"
    check_docker
    
    docker-compose -f docker/docker-compose.dev.yml ps
    
    echo ""
    print_status "Container Health:"
    docker-compose -f docker/docker-compose.dev.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
}

# Main execution
main() {
    case "${1:-help}" in
        start)
            start_dev
            ;;
        stop)
            stop_dev
            ;;
        restart)
            restart_dev
            ;;
        logs)
            show_logs
            ;;
        mongo-logs)
            show_mongo_logs
            ;;
        shell)
            open_app_shell
            ;;
        mongo-shell)
            open_mongo_shell
            ;;
        clean)
            cleanup
            ;;
        build)
            rebuild
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
