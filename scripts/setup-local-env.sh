#!/bin/bash

# FeedbackHub Local Environment Setup Script
# This script helps you set up the local environment for development

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 FeedbackHub Local Environment Setup${NC}"
echo ""

# Check if .env.local exists
if [ -f ".env.local" ]; then
    echo -e "${GREEN}✅ .env.local file already exists${NC}"
    echo -e "${YELLOW}📄 Current .env.local contents:${NC}"
    cat .env.local
    echo ""
else
    echo -e "${YELLOW}📝 Creating .env.local file...${NC}"
    
    # Create .env.local with template
    cat > .env.local << EOF
# MongoDB Atlas Configuration (Option 1 - Recommended)
# Replace with your actual MongoDB Atlas password
MONGODB_PASSWORD=your-mongodb-password

# Direct MongoDB URI (Option 2 - Alternative)
# Uncomment and replace with your full MongoDB URI
# MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/feedbackhub

# Application Configuration
NODE_ENV=development
PORT=3000
NEXT_TELEMETRY_DISABLED=1
EOF

    echo -e "${GREEN}✅ .env.local file created${NC}"
    echo ""
fi

echo -e "${BLUE}🚀 Setup Options:${NC}"
echo ""
echo -e "${YELLOW}Option 1: MongoDB Atlas (Recommended)${NC}"
echo "1. Go to https://cloud.mongodb.com"
echo "2. Create a free cluster"
echo "3. Set up database user with password"
echo "4. Update MONGODB_PASSWORD in .env.local"
echo ""

echo -e "${YELLOW}Option 2: Local MongoDB with Docker${NC}"
echo "1. Run: cd docker && docker-compose up -d"
echo "2. The app will automatically connect to local MongoDB"
echo ""

echo -e "${YELLOW}Option 3: Local MongoDB on localhost${NC}"
echo "1. Install MongoDB locally"
echo "2. Start MongoDB service"
echo "3. The app will automatically connect to localhost:27017"
echo ""

echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo -e "${BLUE}🚀 Next steps:${NC}"
echo "1. Choose one of the setup options above"
echo "2. Run: npm run dev"
echo "3. Test: curl http://localhost:3000/api/health"
echo ""

# Test if the application can start
echo -e "${YELLOW}🧪 Testing application startup...${NC}"
if npm run dev > /dev/null 2>&1 & then
    APP_PID=$!
    sleep 5
    
    # Test health endpoint
    if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Application is running successfully!${NC}"
        echo -e "${GREEN}🌐 Visit: http://localhost:3000${NC}"
    else
        echo -e "${RED}❌ Application failed to start properly${NC}"
        echo -e "${YELLOW}💡 Check the logs above for connection issues${NC}"
    fi
    
    # Kill the background process
    kill $APP_PID 2>/dev/null || true
else
    echo -e "${RED}❌ Failed to start application${NC}"
    echo -e "${YELLOW}💡 Please check your setup and try again${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Setup script completed!${NC}" 