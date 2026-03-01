#!/bin/bash

# CTF Platform Production Runner
# This script starts the backend which serves both API and frontend
# Frontend is served as static files from backend

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PORT=${PORT:-5000}
WORKERS=${WORKERS:-1}

# PID tracking
BACKEND_PID=""

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

# Check if Python dependencies are installed
echo -e "${BLUE}📦 Checking Python dependencies...${NC}"
if [ ! -d ".venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv .venv
fi

source .venv/bin/activate

if ! python3 -c "import flask" &> /dev/null; then
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

# Start backend with Gunicorn (serves both API and frontend)
echo -e "${BLUE}🚀 Starting backend (Gunicorn + Eventlet)...${NC}"
echo -e "${BLUE}   Port: $PORT${NC}"
echo -e "${BLUE}   Workers: $WORKERS${NC}"

gunicorn --worker-class eventlet -w $WORKERS \
    --bind 0.0.0.0:$PORT \
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
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 CTF Platform is running!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📱 Main Platform:${NC}     http://localhost:$PORT"
echo -e "${BLUE}📊 Kiosk Display:${NC}     http://localhost:$PORT/kiosk"
echo -e "${BLUE}🔌 API Endpoint:${NC}      http://localhost:$PORT/api"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo ""

# Keep script running
wait $BACKEND_PID
