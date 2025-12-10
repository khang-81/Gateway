#!/bin/bash
# Scale gateway với nginx load balancer

set -e

echo "============================================================"
echo "Scale MLflow Gateway with Nginx Load Balancer"
echo "============================================================"

# Check .env
if [ ! -f ".env" ]; then
    echo "✗ .env file not found"
    exit 1
fi

# Export API key
export OPENAI_API_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d'=' -f2- | xargs)

# Stop existing containers
echo ""
echo "[1/5] Stopping existing containers..."
docker compose down 2>/dev/null || true
docker compose -f docker-compose.prod.yml down 2>/dev/null || true

# Scale
echo ""
echo "[2/5] Scaling gateway instances..."
OPENAI_API_KEY="$OPENAI_API_KEY" docker compose -f docker-compose.prod.yml up -d --scale mlflow-gateway=3

# Wait for gateway instances
echo ""
echo "[3/5] Waiting for gateway instances to be ready (60 seconds)..."
sleep 60

# Check gateway instances
echo ""
echo "[4/5] Checking gateway instances..."
GATEWAY_COUNT=$(docker ps --filter "name=gateway-mlflow-gateway" --format "{{.Names}}" | wc -l)
echo "Found $GATEWAY_COUNT gateway instance(s)"

for i in $(seq 1 $GATEWAY_COUNT); do
    CONTAINER_NAME="gateway-mlflow-gateway-$i"
    if [ $i -eq 1 ]; then
        CONTAINER_NAME="mlflow-gateway"
    fi
    
    if docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        STATUS=$(docker ps --filter "name=${CONTAINER_NAME}" --format "{{.Status}}")
        echo "  Instance $i: $STATUS"
    fi
done

# Check nginx
echo ""
echo "Checking nginx..."
if docker ps --filter "name=nginx" --format "{{.Names}}" | grep -q nginx; then
    echo "✓ Nginx is running"
    
    # Test nginx config
    echo "Testing nginx configuration..."
    if docker exec mlflow-gateway-nginx nginx -t 2>&1 | grep -q "successful"; then
        echo "✓ Nginx configuration is valid"
    else
        echo "✗ Nginx configuration error"
        docker exec mlflow-gateway-nginx nginx -t
    fi
else
    echo "✗ Nginx is not running"
fi

# Test health through nginx
echo ""
echo "[5/5] Testing health through nginx..."
HEALTH_OK=false
for i in {1..10}; do
    HEALTH=$(curl -s http://localhost:5000/health 2>/dev/null || echo "")
    if echo "$HEALTH" | grep -q "OK"; then
        HEALTH_OK=true
        echo "✓ Health check passed: $HEALTH"
        break
    fi
    if [ $i -lt 10 ]; then
        echo "  Retrying... ($i/10)"
        sleep 5
    fi
done

if [ "$HEALTH_OK" = false ]; then
    echo "✗ Health check failed after multiple attempts"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check nginx logs: docker logs mlflow-gateway-nginx"
    echo "  2. Check gateway logs: docker compose -f docker-compose.prod.yml logs mlflow-gateway"
    echo "  3. Check nginx can reach gateway:"
    echo "     docker exec mlflow-gateway-nginx wget -O- http://mlflow-gateway:5000/health"
    echo "  4. Check network: docker network inspect gateway_mlflow-network"
    exit 1
fi

echo ""
echo "============================================================"
echo "✓ Scaling successful!"
echo "============================================================"
echo ""
echo "Gateway instances: $GATEWAY_COUNT"
echo "Load balancer: http://localhost:5000"
echo ""
echo "Test:"
echo "  curl http://localhost:5000/health"
echo "  curl -X POST http://localhost:5000/gateway/chat/invocations \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"messages\":[{\"role\":\"user\",\"content\":\"Hello\"}]}'"



