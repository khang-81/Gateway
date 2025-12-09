#!/bin/bash
# Fix common issues and test gateway

set -e

echo "============================================================"
echo "MLflow Gateway - Fix and Test"
echo "============================================================"

# 1. Check API key
echo ""
echo "[1/4] Checking API key..."
chmod +x check_api_key.sh
if ./check_api_key.sh; then
    echo "✓ API key is valid"
else
    echo "✗ Please fix API key first"
    exit 1
fi

# 2. Fix permissions
echo ""
echo "[2/4] Fixing script permissions..."
chmod +x evaluate.sh check_api_key.sh 2>/dev/null || true
echo "✓ Scripts are executable"

# 3. Restart container with correct API key
echo ""
echo "[3/4] Restarting container..."
export OPENAI_API_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'" | xargs)
docker compose down
docker compose build --no-cache
OPENAI_API_KEY="$OPENAI_API_KEY" docker compose up -d

echo "Waiting for container to start..."
sleep 10

# 4. Test
echo ""
echo "[4/4] Testing gateway..."
if curl -s http://localhost:5000/health | grep -q "OK"; then
    echo "✓ Health check passed"
    echo ""
    echo "Running evaluation..."
    if command -v python3 &> /dev/null; then
        python3 evaluate_gateway.py
    else
        chmod +x evaluate.sh
        ./evaluate.sh
    fi
else
    echo "✗ Health check failed"
    echo "Check logs: docker compose logs mlflow-gateway"
    exit 1
fi

echo ""
echo "============================================================"
echo "Done!"
echo "============================================================"

