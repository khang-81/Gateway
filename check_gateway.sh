#!/bin/bash
# Quick check gateway status

set -e

echo "============================================================"
echo "Gateway Status Check"
echo "============================================================"

# Check container
echo ""
echo "[1/3] Container Status"
if docker ps --filter "name=mlflow-gateway" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q mlflow-gateway; then
    docker ps --filter "name=mlflow-gateway" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo "✓ Container is running"
else
    echo "✗ Container is not running"
    echo "Start with: docker compose up -d"
    exit 1
fi

# Check health
echo ""
echo "[2/3] Health Check"
HEALTH=$(curl -s http://localhost:5000/health 2>/dev/null || echo "")
if echo "$HEALTH" | grep -q "OK"; then
    echo "✓ Health check passed: $HEALTH"
else
    echo "✗ Health check failed"
    echo "Response: $HEALTH"
    echo ""
    echo "Container might still be starting. Wait 30-60 seconds and try again."
    echo "Or check logs: docker compose logs mlflow-gateway"
fi

# Check API key
echo ""
echo "[3/3] API Key Check"
if [ -f "check_api_key.sh" ]; then
    chmod +x check_api_key.sh 2>/dev/null || true
    ./check_api_key.sh
else
    if [ -f ".env" ]; then
        API_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d'=' -f2- | xargs)
        if [[ "$API_KEY" == *"your_openai_api_key_here"* ]] || [[ "$API_KEY" == *"your_ope"* ]]; then
            echo "✗ API key is still placeholder"
        else
            echo "✓ API key found (length: ${#API_KEY})"
        fi
    else
        echo "⚠ .env file not found"
    fi
fi

echo ""
echo "============================================================"
echo "Status Check Complete"
echo "============================================================"








