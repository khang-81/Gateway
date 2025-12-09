#!/bin/bash
# Check scaling status

set -e

echo "============================================================"
echo "Scaling Status Check"
echo "============================================================"

# Check gateway instances
echo ""
echo "[1/4] Gateway Instances"
GATEWAY_COUNT=$(docker ps --filter "name=gateway-mlflow-gateway" --format "{{.Names}}" | wc -l)
echo "Found $GATEWAY_COUNT gateway instance(s)"

docker ps --filter "name=gateway-mlflow-gateway" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check nginx
echo ""
echo "[2/4] Nginx Load Balancer"
if docker ps --filter "name=nginx" --format "{{.Names}}" | grep -q nginx; then
    echo "✓ Nginx is running"
    docker ps --filter "name=nginx" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo "✗ Nginx is not running"
fi

# Wait for services
echo ""
echo "[3/4] Waiting for services to be ready (30 seconds)..."
sleep 30

# Check health through nginx
echo ""
echo "[4/4] Health Check through Nginx"
for i in {1..5}; do
    HEALTH=$(curl -s http://localhost:5000/health 2>/dev/null || echo "")
    if echo "$HEALTH" | grep -q "OK"; then
        echo "✓ Health check passed: $HEALTH"
        break
    fi
    if [ $i -lt 5 ]; then
        echo "  Retrying... ($i/5)"
        sleep 5
    else
        echo "✗ Health check failed"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check nginx logs: docker logs mlflow-gateway-nginx"
        echo "  2. Check gateway logs: docker compose logs mlflow-gateway"
        echo "  3. Check nginx config: docker exec mlflow-gateway-nginx nginx -t"
    fi
done

echo ""
echo "============================================================"
echo "Status Check Complete"
echo "============================================================"

