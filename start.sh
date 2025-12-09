#!/bin/bash
# Start script that ensures environment variable is loaded

set -e

# Load environment variable from .env file
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | grep OPENAI_API_KEY | xargs)
    echo "✓ Loaded OPENAI_API_KEY from .env"
else
    echo "ERROR: .env file not found!"
    exit 1
fi

# Check if OPENAI_API_KEY is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "ERROR: OPENAI_API_KEY not found in .env file"
    exit 1
fi

# Detect docker-compose command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Start container with environment variable
echo "Starting MLflow Gateway with OPENAI_API_KEY..."
OPENAI_API_KEY="$OPENAI_API_KEY" $DOCKER_COMPOSE up -d

echo ""
echo "✓ Container started"
echo "Waiting 60 seconds for container to fully start..."
sleep 60

echo ""
echo "Container status:"
docker ps --filter "name=mlflow-gateway"

echo ""
echo "Recent logs:"
$DOCKER_COMPOSE logs --tail=20 mlflow-gateway

echo ""
echo "Testing health endpoint:"
curl -s http://localhost:5000/health || echo "Health check failed (container might still be starting)"

echo ""
echo "To view full logs: $DOCKER_COMPOSE logs -f mlflow-gateway"

