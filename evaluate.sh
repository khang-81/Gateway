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

# Check health
echo ""
echo "[1/3] Health Check"
HEALTH=$(curl -s "${GATEWAY_URL}/health" || echo "")
if echo "$HEALTH" | grep -q "OK"; then
    echo "✓ Gateway is healthy"
else
    echo "✗ Gateway health check failed"
    exit 1
fi

# Run evaluation
echo ""
echo "[2/3] Running Evaluation"
if command -v python3 &> /dev/null; then
    python3 evaluate_gateway.py --url "$GATEWAY_URL"
else
    echo "✗ Python3 not found. Please install Python to run evaluation."
    exit 1
fi

# Analyze costs
echo ""
echo "[3/3] Cost Analysis"
if command -v python3 &> /dev/null; then
    python3 analyze_costs.py --container mlflow-gateway
else
    echo "⚠ Python3 not found. Cannot analyze costs."
fi

echo ""
echo "============================================================"
echo "Evaluation Complete"
echo "============================================================"

