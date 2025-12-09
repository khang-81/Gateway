#!/bin/bash
# MLflow Gateway Evaluation Script
# Đánh giá gateway với requests thực tế

set -e

GATEWAY_URL="${GATEWAY_URL:-http://localhost:5000}"

echo "============================================================"
echo "MLflow Gateway Evaluation"
echo "Gateway URL: $GATEWAY_URL"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"

# Check API key first
echo ""
echo "[0/4] Checking API Key"
if [ -f "check_api_key.sh" ]; then
    chmod +x check_api_key.sh 2>/dev/null || true
    if ./check_api_key.sh; then
        echo "✓ API key is valid"
    else
        echo "✗ API key check failed"
        echo ""
        echo "Please fix API key:"
        echo "  1. Edit .env file: nano .env"
        echo "  2. Update OPENAI_API_KEY=sk-your-actual-key-here"
        echo "  3. Restart container: docker compose restart"
        exit 1
    fi
else
    echo "⚠ check_api_key.sh not found, skipping API key check"
fi

# Check health with retries
echo ""
echo "[1/4] Health Check"
HEALTH_OK=false
for i in {1..3}; do
    HEALTH=$(curl -s "${GATEWAY_URL}/health" || echo "")
    if echo "$HEALTH" | grep -q "OK"; then
        HEALTH_OK=true
        break
    fi
    if [ $i -lt 3 ]; then
        echo "  Retrying health check... ($i/3)"
        sleep 5
    fi
done

if [ "$HEALTH_OK" = true ]; then
    echo "✓ Gateway is healthy"
else
    echo "✗ Gateway health check failed"
    echo ""
    echo "Checking container status..."
    docker ps --filter "name=mlflow-gateway" 2>/dev/null || true
    echo ""
    echo "Recent logs:"
    docker compose logs --tail=20 mlflow-gateway 2>/dev/null || true
    echo ""
    echo "Please check:"
    echo "  1. Container is running: docker ps"
    echo "  2. Container logs: docker compose logs mlflow-gateway"
    echo "  3. API key is valid: ./check_api_key.sh"
    exit 1
fi

# Run evaluation
echo ""
echo "[2/4] Running Evaluation"
if command -v python3 &> /dev/null; then
    if python3 evaluate_gateway.py --url "$GATEWAY_URL"; then
        echo "✓ Evaluation completed"
    else
        echo "✗ Evaluation failed"
        echo "  Check API key and gateway status"
    fi
else
    echo "✗ Python3 not found. Please install Python to run evaluation."
    exit 1
fi

# Analyze costs
echo ""
echo "[3/4] Cost Analysis"
if command -v python3 &> /dev/null; then
    python3 analyze_costs.py --container mlflow-gateway || echo "⚠ No usage data found (normal if no successful requests)"
else
    echo "⚠ Python3 not found. Cannot analyze costs."
fi

echo ""
echo "============================================================"
echo "Evaluation Complete"
echo "============================================================"

