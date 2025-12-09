#!/bin/bash
# Script to fix environment variable issue permanently

set -e

echo "=========================================="
echo "Fixing Environment Variable Issue"
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
echo "✓ OPENAI_API_KEY found"
echo ""

# Step 2: Stop container
echo "[2/4] Stopping container..."
docker compose down
echo "✓ Container stopped"
echo ""

# Step 3: Export environment variable
echo "[3/4] Exporting environment variable..."
export OPENAI_API_KEY="$OPENAI_KEY"
echo "✓ Environment variable exported"
echo ""

# Step 4: Start container with environment variable
echo "[4/4] Starting container with environment variable..."
docker compose build --no-cache
OPENAI_API_KEY="$OPENAI_API_KEY" docker compose up -d

echo ""
echo "=========================================="
echo "Fix Applied!"
echo "=========================================="
echo ""
echo "Waiting 60 seconds for container to start..."
sleep 60

echo ""
echo "Checking container status:"
docker ps --filter "name=mlflow-gateway"

echo ""
echo "Checking if OPENAI_API_KEY is in container:"
docker exec mlflow-gateway env | grep OPENAI || echo "⚠ OPENAI_API_KEY not found in container"

echo ""
echo "Recent logs:"
docker compose logs --tail=20 mlflow-gateway

echo ""
echo "Testing health endpoint:"
sleep 5
curl -s http://localhost:5000/health && echo "" || echo "Health check failed (container might still be starting)"

echo ""
echo "To view full logs: docker compose logs -f mlflow-gateway"
echo ""

