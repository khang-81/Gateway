#!/bin/bash
# Quick status check script for MLflow Gateway

echo "=========================================="
echo "MLflow Gateway - Status Check"
echo "=========================================="
echo ""

# Check container status
echo "[1/5] Container Status:"
docker ps --filter "name=mlflow-gateway" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Check if container is running
if docker ps --filter "name=mlflow-gateway" --format "{{.Names}}" | grep -q "mlflow-gateway"; then
    echo "✓ Container is running"
else
    echo "✗ Container is NOT running"
    echo "Checking stopped containers..."
    docker ps -a --filter "name=mlflow-gateway"
    exit 1
fi

echo ""
echo "[2/5] Recent Logs (last 30 lines):"
docker compose logs --tail=30 mlflow-gateway
echo ""

echo "[3/5] Checking for errors in logs:"
ERRORS=$(docker compose logs mlflow-gateway 2>&1 | grep -i "error\|fail\|exception" | tail -10)
if [ -z "$ERRORS" ]; then
    echo "✓ No errors found in recent logs"
else
    echo "⚠ Found errors:"
    echo "$ERRORS"
fi
echo ""

echo "[4/5] Testing Health Endpoint:"
sleep 2
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost:5000/health 2>&1)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
BODY=$(echo "$HEALTH_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Health check PASSED (HTTP $HTTP_CODE)"
    echo "Response: $BODY"
else
    echo "✗ Health check FAILED (HTTP $HTTP_CODE)"
    echo "Response: $BODY"
    echo ""
    echo "Container might still be starting. MLflow Gateway needs 30-60 seconds to fully start."
    echo "Wait a bit longer and try: curl http://localhost:5000/health"
fi
echo ""

echo "[5/5] Testing API Endpoint:"
sleep 2
API_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:5000/gateway/chat/invocations \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"test"}]}' 2>&1)
API_HTTP_CODE=$(echo "$API_RESPONSE" | tail -n1)
API_BODY=$(echo "$API_RESPONSE" | sed '$d')

if [ "$API_HTTP_CODE" = "200" ]; then
    echo "✓ API endpoint PASSED (HTTP $API_HTTP_CODE)"
    echo "Response preview: $(echo "$API_BODY" | head -c 200)..."
else
    echo "✗ API endpoint FAILED (HTTP $API_HTTP_CODE)"
    echo "Response: $API_BODY"
fi
echo ""

echo "=========================================="
echo "Summary:"
echo "=========================================="
echo "Container: $(docker ps --filter "name=mlflow-gateway" --format "{{.Status}}")"
echo "Health: $([ "$HTTP_CODE" = "200" ] && echo "✓ OK" || echo "✗ Failed")"
echo "API: $([ "$API_HTTP_CODE" = "200" ] && echo "✓ OK" || echo "✗ Failed")"
echo ""
echo "To view full logs: docker compose logs -f mlflow-gateway"
echo ""

