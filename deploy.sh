#!/bin/bash
# MLflow Gateway - Linux Deploy Script
# Build and run the MLflow Gateway container on Linux server
# This script is meant to be run on the server after files are uploaded

set -e

# Detect docker-compose command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo "Building MLflow Gateway Docker image..."
$DOCKER_COMPOSE build

echo "Starting MLflow Gateway container..."
$DOCKER_COMPOSE up -d

echo "Waiting for container to start..."
sleep 5

echo "Container status:"
docker ps --filter "name=mlflow-gateway"

echo ""
echo "Showing logs (Ctrl+C to exit):"
$DOCKER_COMPOSE logs -f mlflow-gateway

