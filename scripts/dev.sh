#!/bin/bash

# Development script for FeedbackHub
# This script helps manage the development environment

echo "🚀 FeedbackHub Development Script"
echo "=================================="

# Function to check if port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "⚠️  Port $1 is already in use"
        return 1
    else
        echo "✅ Port $1 is available"
        return 0
    fi
}

# Function to stop Docker containers
stop_docker() {
    echo "🛑 Stopping Docker containers..."
    cd docker && docker-compose down && cd ..
    echo "✅ Docker containers stopped"
}

# Function to start development server
start_dev() {
    echo "🚀 Starting development server..."
    npm run dev
}

# Function to start Docker development environment
start_docker_dev() {
    echo "🐳 Starting Docker development environment..."
    cd docker && docker-compose -f docker-compose.dev.yml up --build -d && cd ..
    echo "✅ Docker development environment started"
    echo "🌐 Application available at: http://localhost:3000"
    echo "📊 MongoDB available at: localhost:27017"
}

# Function to start Docker production environment
start_docker_prod() {
    echo "🐳 Starting Docker production environment..."
    cd docker && docker-compose up --build -d && cd ..
    echo "✅ Docker production environment started"
    echo "🌐 Application available at: http://localhost:3000"
}

# Function to view logs
view_logs() {
    echo "📋 Viewing Docker logs..."
    cd docker && docker-compose -f docker-compose.dev.yml logs -f app && cd ..
}

# Main script logic
case "${1:-dev}" in
    "dev")
        echo "📋 Starting development mode..."
        
        # Check if port 3000 is available
        if ! check_port 3000; then
            echo "🔍 Checking what's using port 3000..."
            lsof -i :3000
            echo ""
            read -p "Do you want to stop Docker containers to free up port 3000? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                stop_docker
            else
                echo "❌ Cannot start development server. Port 3000 is in use."
                exit 1
            fi
        fi
        
        start_dev
        ;;
    "docker-dev")
        echo "🐳 Starting Docker development environment..."
        start_docker_dev
        ;;
    "docker-prod")
        echo "🐳 Starting Docker production environment..."
        start_docker_prod
        ;;
    "stop")
        echo "🛑 Stopping all services..."
        stop_docker
        echo "✅ All services stopped"
        ;;
    "restart")
        echo "🔄 Restarting development environment..."
        stop_docker
        sleep 2
        start_dev
        ;;
    "logs")
        view_logs
        ;;
    "status")
        echo "📊 Service Status:"
        echo "=================="
        
        if check_port 3000; then
            echo "✅ Development server: Running on port 3000"
        else
            echo "❌ Development server: Not running"
        fi
        
        if docker ps | grep -q "docker-app-1"; then
            echo "✅ Docker app: Running"
        else
            echo "❌ Docker app: Not running"
        fi
        
        if docker ps | grep -q "docker-mongo-1"; then
            echo "✅ Docker MongoDB: Running"
        else
            echo "❌ Docker MongoDB: Not running"
        fi
        
        # Check MongoDB connection
        if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
            echo "✅ API Health: Responding"
        else
            echo "❌ API Health: Not responding"
        fi
        ;;
    *)
        echo "Usage: $0 {dev|docker-dev|docker-prod|stop|restart|logs|status}"
        echo ""
        echo "Commands:"
        echo "  dev        - Start local development server (default)"
        echo "  docker-dev - Start Docker development environment with hot reload"
        echo "  docker-prod- Start Docker production environment"
        echo "  stop       - Stop all services"
        echo "  restart    - Restart development environment"
        echo "  logs       - View Docker logs"
        echo "  status     - Show service status"
        exit 1
        ;;
esac 