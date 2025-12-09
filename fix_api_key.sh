#!/bin/bash
# Fix API key issue

set -e

echo "============================================================"
echo "Fix API Key Issue"
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

# Check current API key
API_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'" | xargs)

if [ -z "$API_KEY" ]; then
    echo "✗ OPENAI_API_KEY not found in .env"
    exit 1
fi

# Check if placeholder
if [[ "$API_KEY" == *"your_openai_api_key_here"* ]] || [[ "$API_KEY" == *"your_ope"* ]]; then
    echo "✗ API key is still placeholder!"
    echo "Current value: ${API_KEY:0:30}..."
    echo ""
    echo "Please update .env file with your actual OpenAI API key:"
    echo "  1. Edit .env: nano .env"
    echo "  2. Change: OPENAI_API_KEY=sk-your-actual-key-here"
    echo "  3. Save and exit (Ctrl+X, Y, Enter)"
    echo ""
    echo "Then restart container:"
    echo "  export OPENAI_API_KEY=\$(grep '^OPENAI_API_KEY=' .env | cut -d'=' -f2- | xargs)"
    echo "  docker compose down"
    echo "  docker compose build --no-cache"
    echo "  OPENAI_API_KEY=\"\$OPENAI_API_KEY\" docker compose up -d"
    exit 1
fi

echo "✓ API key found (length: ${#API_KEY})"

# Export and restart
echo ""
echo "Restarting container with new API key..."
export OPENAI_API_KEY

# Stop container
docker compose down

# Rebuild and start with explicit environment variable
echo "Rebuilding container..."
OPENAI_API_KEY="$API_KEY" docker compose up -d --build

echo ""
echo "Waiting for container to start (60 seconds)..."
sleep 60

# Check health with retries
HEALTH_OK=false
for i in {1..5}; do
    if curl -s http://localhost:5000/health | grep -q "OK"; then
        HEALTH_OK=true
        break
    fi
    echo "  Waiting for health check... ($i/5)"
    sleep 10
done

if [ "$HEALTH_OK" = true ]; then
    echo "✓ Container restarted successfully"
    echo "✓ Gateway is healthy"
else
    echo "⚠ Health check failed after multiple attempts"
    echo ""
    echo "Checking container status..."
    docker ps --filter "name=mlflow-gateway"
    echo ""
    echo "Recent logs:"
    docker compose logs --tail=30 mlflow-gateway
    echo ""
    echo "If container is restarting, check:"
    echo "  1. API key is valid: ./check_api_key.sh"
    echo "  2. Container logs: docker compose logs mlflow-gateway"
fi

