#!/bin/bash
# Script to fix environment variable issue and restart container

set -e

echo "=========================================="
echo "Fixing MLflow Gateway Environment Issue"
echo "=========================================="
echo ""

# Step 1: Check .env file
echo "[1/4] Checking .env file..."
if [ ! -f ".env" ]; then
    echo "ERROR: .env file not found!"
    exit 1
fi

OPENAI_KEY=$(grep "^OPENAI_API_KEY=" .env | head -1 | cut -d'=' -f2)
if [ -z "$OPENAI_KEY" ]; then
    echo "ERROR: OPENAI_API_KEY not found in .env file"
    exit 1
fi

echo "✓ .env file found"
echo "✓ OPENAI_API_KEY found (length: ${#OPENAI_KEY} chars)"
echo ""

# Step 2: Export environment variable
echo "[2/4] Exporting environment variable..."
export OPENAI_API_KEY="$OPENAI_KEY"
echo "✓ Environment variable exported"
echo ""

# Step 3: Check docker-compose.yml
echo "[3/4] Checking docker-compose.yml..."
if ! grep -q "environment:" docker-compose.yml; then
    echo "⚠ docker-compose.yml missing environment section"
    echo "Adding environment section..."
    
    # Backup
    cp docker-compose.yml docker-compose.yml.backup
    
    # Add environment section after env_file
    sed -i '/env_file:/a\    environment:\n      - OPENAI_API_KEY=${OPENAI_API_KEY}' docker-compose.yml
    
    echo "✓ docker-compose.yml updated"
else
    echo "✓ docker-compose.yml has environment section"
fi
echo ""

# Step 4: Stop, rebuild and restart
echo "[4/4] Stopping, rebuilding and restarting container..."
docker compose down

echo "Rebuilding image..."
docker compose build --no-cache

echo "Starting container with environment variable..."
OPENAI_API_KEY="$OPENAI_KEY" docker compose up -d

echo ""
echo "=========================================="
echo "Fix Complete!"
echo "=========================================="
echo ""
echo "Waiting 60 seconds for container to start..."
sleep 60

echo ""
echo "Checking container status:"
docker ps --filter "name=mlflow-gateway"

echo ""
echo "Recent logs:"
docker compose logs --tail=20 mlflow-gateway

echo ""
echo "Testing health endpoint:"
sleep 5
curl -s http://localhost:5000/health || echo "Health check failed (container might still be starting)"

echo ""
echo "To view full logs: docker compose logs -f mlflow-gateway"
echo ""

