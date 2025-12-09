#!/bin/bash
# MLflow Gateway - Interactive Setup and Deploy Script
# For use in Teleport Web Terminal
# This script will guide you through cloning the repository and deploying

set -e

echo "=========================================="
echo "MLflow Gateway - Setup and Deploy"
echo "=========================================="
echo ""

# Step 1: Check prerequisites
echo "[1/6] Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed"
    echo "Please install Docker first"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon is not running"
    echo "Please start Docker service: sudo systemctl start docker"
    exit 1
fi
echo "✓ Docker is installed and running"

# Check docker-compose
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
    echo "✓ docker compose is available"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
    echo "✓ docker-compose is available"
else
    echo "ERROR: docker-compose is not installed"
    exit 1
fi

# Check Git
if ! command -v git &> /dev/null; then
    echo "ERROR: Git is not installed"
    echo "Please install Git first: sudo apt-get install git"
    exit 1
fi
echo "✓ Git is installed"

# Step 2: Get Git repository URL
echo ""
echo "[2/6] Git Repository Setup"
echo "Current directory: $(pwd)"

if [ -d "mlflow-gateway" ] && [ -f "mlflow-gateway/config.yaml" ]; then
    echo "✓ Repository already exists in current directory"
    read -p "Do you want to update it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Updating repository..."
        cd mlflow-gateway
        git pull || echo "Warning: Could not pull updates"
        cd ..
    fi
    REPO_DIR="mlflow-gateway"
else
    read -p "Enter Git repository URL (or press Enter to use current directory): " REPO_URL
    echo
    
    if [ -z "$REPO_URL" ]; then
        if [ -f "config.yaml" ] && [ -f "Dockerfile" ]; then
            echo "✓ Using current directory as deployment directory"
            REPO_DIR="."
        else
            echo "ERROR: No repository URL provided and current directory doesn't contain MLflow Gateway files"
            exit 1
        fi
    else
        echo "Cloning repository..."
        if [ -d "mlflow-gateway" ]; then
            read -p "Directory 'mlflow-gateway' exists. Remove and re-clone? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf mlflow-gateway
            else
                echo "Using existing directory"
                REPO_DIR="mlflow-gateway"
            fi
        fi
        
        if [ ! -d "mlflow-gateway" ]; then
            git clone "$REPO_URL" mlflow-gateway || {
                echo "ERROR: Failed to clone repository"
                exit 1
            }
        fi
        REPO_DIR="mlflow-gateway"
    fi
fi

cd "$REPO_DIR"
echo "Working directory: $(pwd)"

# Step 3: Setup .env file
echo ""
echo "[3/6] Environment Variables Setup"

if [ -f ".env" ]; then
    echo "✓ .env file already exists"
    read -p "Do you want to update it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Using existing .env file"
        SKIP_ENV=true
    fi
fi

if [ "$SKIP_ENV" != "true" ]; then
    if [ -f "env.template" ]; then
        cp env.template .env
    elif [ -f ".env.example" ]; then
        cp .env.example .env
    else
        echo "Creating .env file..."
        cat > .env << EOF
OPENAI_API_KEY=your_openai_api_key_here
EOF
    fi
    
    echo ""
    echo "Please enter your OpenAI API Key:"
    read -sp "OPENAI_API_KEY: " API_KEY
    echo
    
    if [ -z "$API_KEY" ] || [ "$API_KEY" = "your_openai_api_key_here" ]; then
        echo "WARNING: API key not set or using placeholder"
        echo "Please edit .env file manually: nano .env"
    else
        sed -i "s|OPENAI_API_KEY=.*|OPENAI_API_KEY=$API_KEY|" .env
        chmod 600 .env
        echo "✓ .env file updated"
    fi
fi

# Step 4: Verify required files
echo ""
echo "[4/6] Verifying required files..."

REQUIRED_FILES=("config.yaml" "Dockerfile" "docker-compose.yml")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "ERROR: Missing required files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    exit 1
fi
echo "✓ All required files present"

# Step 5: Deploy
echo ""
echo "[5/6] Deploying MLflow Gateway..."

# Load environment variable from .env file
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | grep OPENAI_API_KEY | xargs)
    echo "✓ Environment variable loaded from .env"
fi

# Make deploy script executable if it exists
if [ -f "deploy_web.sh" ]; then
    chmod +x deploy_web.sh
    ./deploy_web.sh
elif [ -f "deploy.sh" ]; then
    chmod +x deploy.sh
    # Use deploy.sh but don't follow logs
    $DOCKER_COMPOSE down 2>/dev/null || true
    $DOCKER_COMPOSE build
    # Ensure OPENAI_API_KEY is available
    if [ -n "$OPENAI_API_KEY" ]; then
        OPENAI_API_KEY="$OPENAI_API_KEY" $DOCKER_COMPOSE up -d
    else
        $DOCKER_COMPOSE up -d
    fi
    sleep 10
    docker ps --filter "name=mlflow-gateway"
else
    # Manual deploy
    $DOCKER_COMPOSE down 2>/dev/null || true
    $DOCKER_COMPOSE build
    # Ensure OPENAI_API_KEY is available
    if [ -n "$OPENAI_API_KEY" ]; then
        OPENAI_API_KEY="$OPENAI_API_KEY" $DOCKER_COMPOSE up -d
    else
        $DOCKER_COMPOSE up -d
    fi
    sleep 10
    docker ps --filter "name=mlflow-gateway"
fi

# Step 6: Verify deployment
echo ""
echo "[6/6] Verifying deployment..."

sleep 20

if docker ps --filter "name=mlflow-gateway" --format "{{.Names}}" | grep -q "mlflow-gateway"; then
    echo "✓ Container is running"
    
    # Test health endpoint
    echo "Testing health endpoint..."
    sleep 10
    if curl -f -s http://localhost:5000/health > /dev/null 2>&1; then
        echo "✓ Health check passed"
    else
        echo "⚠ Health check failed, but container is running"
    fi
else
    echo "✗ Container failed to start"
    echo "Checking logs..."
    $DOCKER_COMPOSE logs mlflow-gateway | tail -20
    exit 1
fi

echo ""
echo "=========================================="
echo "Setup and Deployment Complete!"
echo "=========================================="
echo ""
echo "Service Information:"
echo "  URL: http://localhost:5000"
echo "  Health: http://localhost:5000/health"
echo "  API: http://localhost:5000/gateway/chat/invocations"
echo ""
echo "Useful Commands:"
echo "  View logs: $DOCKER_COMPOSE logs -f mlflow-gateway"
echo "  Stop: $DOCKER_COMPOSE down"
echo "  Restart: $DOCKER_COMPOSE restart"
echo "  Status: docker ps --filter name=mlflow-gateway"
echo ""

