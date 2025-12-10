#!/bin/bash
# Fix environment variable issue and restart container

set -e

echo "============================================================"
echo "Fix Environment Variable and Restart Container"
echo "============================================================"

# Check .env file
if [ ! -f ".env" ]; then
    echo "✗ .env file not found"
    echo "Creating from template..."
    cp env.template .env
    echo ""
    echo "Please edit .env and add your OpenAI API key:"
    echo "  nano .env"
    echo "  # Add: OPENAI_API_KEY=sk-your-actual-key-here"
    exit 1
fi

# Read API key from .env
API_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'" | xargs)

if [ -z "$API_KEY" ]; then
    echo "✗ OPENAI_API_KEY not found in .env"
    exit 1
fi

# Check if placeholder
if [[ "$API_KEY" == *"your_openai_api_key_here"* ]] || [[ "$API_KEY" == *"your_ope"* ]]; then
    echo "✗ API key is still placeholder!"
    echo "Please update .env file with your actual OpenAI API key"
    exit 1
fi

echo "✓ API key found (length: ${#API_KEY})"

# Export API key to current shell
export OPENAI_API_KEY="$API_KEY"

# Stop container
echo ""
echo "Stopping container..."
docker compose down

# Verify .env file format
echo ""
echo "Verifying .env file format..."
if grep -q "^OPENAI_API_KEY=" .env; then
    echo "✓ .env file format is correct"
else
    echo "✗ .env file format is incorrect"
    echo "Expected: OPENAI_API_KEY=sk-..."
    exit 1
fi

# Rebuild and start with explicit environment variable
echo ""
echo "Rebuilding and starting container..."
echo "Using API key from .env file..."

# Use docker compose with explicit environment variable
OPENAI_API_KEY="$API_KEY" docker compose up -d --build

echo ""
echo "Waiting for container to start (60 seconds)..."
sleep 60

# Check container status
echo ""
echo "Checking container status..."
CONTAINER_STATUS=$(docker ps --filter "name=mlflow-gateway" --format "{{.Status}}" 2>/dev/null || echo "")

if echo "$CONTAINER_STATUS" | grep -q "Up"; then
    echo "✓ Container is running: $CONTAINER_STATUS"
else
    echo "⚠ Container status: $CONTAINER_STATUS"
    echo ""
    echo "Checking logs..."
    docker compose logs --tail=20 mlflow-gateway
fi

# Check health with retries
echo ""
echo "Checking health endpoint..."
HEALTH_OK=false
for i in {1..5}; do
    HEALTH=$(curl -s http://localhost:5000/health 2>/dev/null || echo "")
    if echo "$HEALTH" | grep -q "OK"; then
        HEALTH_OK=true
        break
    fi
    if [ $i -lt 5 ]; then
        echo "  Retrying... ($i/5)"
        sleep 10
    fi
done

if [ "$HEALTH_OK" = true ]; then
    echo "✓ Gateway is healthy"
    echo ""
    echo "============================================================"
    echo "✓ Container restarted successfully!"
    echo "============================================================"
else
    echo "✗ Health check failed"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check logs: docker compose logs mlflow-gateway"
    echo "  2. Verify API key in container:"
    echo "     docker exec mlflow-gateway env | grep OPENAI"
    echo "  3. Check .env file format: cat .env"
    exit 1
fi



