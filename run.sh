#!/bin/bash

# CTF Platform Production Runner
# This script starts both backend (via Gunicorn) and frontend (via npm)
# and ensures both are killed when the script is terminated

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_PORT=${BACKEND_PORT:-5000}
FRONTEND_PORT=${FRONTEND_PORT:-3000}
WORKERS=${WORKERS:-4}

# PID tracking
BACKEND_PID=""
FRONTEND_PID=""

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Shutting down CTF Platform...${NC}"
    
    # Kill backend
    if [ ! -z "$BACKEND_PID" ]; then
        echo -e "${BLUE}Stopping backend (PID: $BACKEND_PID)...${NC}"
        kill -TERM "$BACKEND_PID" 2>/dev/null || true
        wait "$BACKEND_PID" 2>/dev/null || true
    fi
    
    # Kill frontend
    if [ ! -z "$FRONTEND_PID" ]; then
        echo -e "${BLUE}Stopping frontend (PID: $FRONTEND_PID)...${NC}"
        kill -TERM "$FRONTEND_PID" 2>/dev/null || true
        wait "$FRONTEND_PID" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ CTF Platform stopped${NC}"
    exit 0
}

# Trap signals
trap cleanup SIGINT SIGTERM EXIT

# Banner
echo "╔════════════════════════════════════════════════════════════╗"
echo "║        🚩 CTF Platform - Production Deployment 🚩         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Error: Python 3 is not installed${NC}"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Error: Node.js is not installed${NC}"
    exit 1
fi

# Check if required Python packages are installed
echo -e "${BLUE}📦 Checking Python dependencies...${NC}"
if ! python3 -c "import gunicorn" 2>/dev/null; then
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    pip install -r requirements.txt
fi

# Check if frontend dependencies are installed
echo -e "${BLUE}📦 Checking frontend dependencies...${NC}"
if [ ! -d "frontend/node_modules" ]; then
    echo -e "${YELLOW}Installing frontend dependencies...${NC}"
    cd frontend
    npm install
    cd ..
fi

# Build frontend for production
echo -e "${BLUE}🏗️  Building frontend for production...${NC}"
cd frontend
npm run build
cd ..

if [ ! -d "frontend/dist" ]; then
    echo -e "${RED}❌ Error: Frontend build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend built successfully${NC}"
echo ""

# Start backend with Gunicorn
echo -e "${BLUE}🚀 Starting backend (Gunicorn + Eventlet)...${NC}"
echo -e "${BLUE}   Port: $BACKEND_PORT${NC}"
echo -e "${BLUE}   Workers: $WORKERS${NC}"

gunicorn --worker-class eventlet -w 1 \
    --bind 0.0.0.0:$BACKEND_PORT \
    --access-logfile - \
    --error-logfile - \
    app:app &

BACKEND_PID=$!

# Wait for backend to start
sleep 2

# Check if backend is running
if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo -e "${RED}❌ Error: Backend failed to start${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Backend started (PID: $BACKEND_PID)${NC}"
echo ""

# Start frontend with a simple HTTP server (serving the built files)
echo -e "${BLUE}🚀 Starting frontend server...${NC}"
echo -e "${BLUE}   Port: $FRONTEND_PORT${NC}"

cd frontend/dist
python3 -m http.server $FRONTEND_PORT &
FRONTEND_PID=$!
cd ../..

# Wait for frontend to start
sleep 2

# Check if frontend is running
if ! kill -0 $FRONTEND_PID 2>/dev/null; then
    echo -e "${RED}❌ Error: Frontend failed to start${NC}"
    cleanup
    exit 1
fi

echo -e "${GREEN}✅ Frontend started (PID: $FRONTEND_PID)${NC}"
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                   🎉 Platform Running! 🎉                  ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║  Frontend: http://localhost:$FRONTEND_PORT                           ║"
echo "║  Backend:  http://localhost:$BACKEND_PORT                            ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║  Press Ctrl+C to stop all services                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Wait for both processes
wait $BACKEND_PID $FRONTEND_PID
