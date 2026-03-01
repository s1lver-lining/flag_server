#!/bin/bash

# Health check script for CTF Platform
# Returns 0 if healthy, 1 if unhealthy

BACKEND_PORT=${BACKEND_PORT:-5000}
FRONTEND_PORT=${FRONTEND_PORT:-3000}

echo "🏥 CTF Platform Health Check"
echo "=============================="

# Check backend
echo -n "Backend (port $BACKEND_PORT): "
if curl -sf http://localhost:$BACKEND_PORT/api/scoreboard > /dev/null 2>&1; then
    echo "✅ Healthy"
    BACKEND_OK=1
else
    echo "❌ Down"
    BACKEND_OK=0
fi

# Check frontend
echo -n "Frontend (port $FRONTEND_PORT): "
if curl -sf http://localhost:$FRONTEND_PORT > /dev/null 2>&1; then
    echo "✅ Healthy"
    FRONTEND_OK=1
else
    echo "❌ Down"
    FRONTEND_OK=0
fi

# Check data directory
echo -n "Data directory: "
if [ -d "data" ] && [ -w "data" ]; then
    echo "✅ Accessible"
    DATA_OK=1
else
    echo "❌ Not accessible"
    DATA_OK=0
fi

echo ""
echo "=============================="

# Overall health
if [ $BACKEND_OK -eq 1 ] && [ $FRONTEND_OK -eq 1 ] && [ $DATA_OK -eq 1 ]; then
    echo "✅ Platform is healthy"
    exit 0
else
    echo "❌ Platform has issues"
    exit 1
fi
