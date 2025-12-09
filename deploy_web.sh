#!/bin/bash
# MLflow Gateway - Web Terminal Deploy Script
# Simple deployment script for use in Teleport Web Terminal
# Assumes repository is already cloned and .env file exists

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "MLflow Gateway - Web Terminal Deployment"
echo "=========================================="
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "ERROR: .env file not found!"
    echo "Please create .env file from env.template:"
    echo "  cp env.template .env"
    echo "  # Then edit .env and add your OPENAI_API_KEY"
    exit 1
fi

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon is not running"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "ERROR: docker-compose is not installed"
    exit 1
fi

# Use docker compose (newer) or docker-compose (older)
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo "[1/4] Stopping existing containers (if any)..."
$DOCKER_COMPOSE down 2>/dev/null || true

echo ""
echo "[2/4] Building MLflow Gateway Docker image..."
$DOCKER_COMPOSE build

echo ""
echo "[3/4] Starting MLflow Gateway container..."
$DOCKER_COMPOSE up -d

echo ""
echo "[4/4] Waiting for container to start and checking status..."
sleep 10

# Check container status
if docker ps --filter "name=mlflow-gateway" --format "{{.Names}}" | grep -q "mlflow-gateway"; then
    echo "✓ Container is running"
else
    echo "✗ Container failed to start"
    echo "Checking logs..."
    $DOCKER_COMPOSE logs mlflow-gateway
    exit 1
fi

# Wait a bit more for health check
echo "Waiting for health check (30 seconds)..."
sleep 30

# Test health endpoint
echo ""
echo "Testing health endpoint..."
if curl -f -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✓ Health check passed"
else
    echo "⚠ Health check failed, but container is running"
    echo "Check logs with: $DOCKER_COMPOSE logs -f mlflow-gateway"
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Service URL: http://localhost:5000"
echo "Health: http://localhost:5000/health"
echo "API: http://localhost:5000/gateway/chat/invocations"
echo ""
echo "Useful commands:"
echo "  View logs: $DOCKER_COMPOSE logs -f mlflow-gateway"
echo "  Stop: $DOCKER_COMPOSE down"
echo "  Restart: $DOCKER_COMPOSE restart"
echo "  Status: docker ps --filter name=mlflow-gateway"
echo ""

