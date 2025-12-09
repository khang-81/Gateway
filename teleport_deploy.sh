#!/bin/bash
# MLflow Gateway - Teleport Deployment Script (Bash)
# Deploy MLflow Gateway to server 10.3.49.202 via Teleport
# Requirements: Teleport client (tsh) installed and logged in

set -e

SERVER_IP="10.3.49.202"
SERVER_USER="${1:-$(whoami)}"  # Use first argument or current user
DEPLOY_PATH="/opt/mlflow-gateway"

echo "=== MLflow Gateway Deployment Script (Teleport) ==="
echo "Server: $SERVER_IP"
echo "User: $SERVER_USER"
echo "Deploy path: $DEPLOY_PATH"
echo ""

# Step 0: Check Teleport client
echo "[0/8] Checking Teleport client (tsh)..."
if ! command -v tsh &> /dev/null; then
    echo "ERROR: Teleport client (tsh) is not installed"
    echo "Please install Teleport client:"
    echo "  Linux: https://goteleport.com/docs/installation/"
    echo "  Or: curl https://goteleport.com/static/install.sh | bash -s 13.4.15"
    exit 1
fi
echo "OK Teleport client is installed"

# Step 1: Check Teleport login status
echo ""
echo "[1/8] Checking Teleport login status..."
if ! tsh status &> /dev/null; then
    echo "WARNING: Not logged in to Teleport"
    echo "Please login to Teleport first:"
    echo "  tsh login --proxy=<teleport-proxy-address>"
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "OK Logged in to Teleport"
    tsh status
fi

# Step 2: Test connection to server via Teleport
echo ""
echo "[2/8] Testing connection to server via Teleport..."
if ! tsh ssh -o ConnectTimeout=5 "${SERVER_USER}@${SERVER_IP}" "echo 'Connection test'" &> /dev/null; then
    echo "ERROR: Cannot connect to $SERVER_IP via Teleport"
    echo "Please check:"
    echo "  - Teleport proxy is running"
    echo "  - You have access to server $SERVER_IP"
    echo "  - Username $SERVER_USER is correct"
    exit 1
fi
echo "OK Connection successful via Teleport"

# Step 3: Create directory on server
echo ""
echo "[3/8] Creating directory on server..."
tsh ssh "${SERVER_USER}@${SERVER_IP}" "sudo mkdir -p $DEPLOY_PATH && sudo chown \$USER:\$USER $DEPLOY_PATH"
if [ $? -ne 0 ]; then
    echo "ERROR: Cannot create directory on server"
    exit 1
fi
echo "OK Directory created"

# Step 4: Upload files
echo ""
echo "[4/8] Uploading files to server via Teleport..."
files_to_upload=(
    "config.yaml"
    "Dockerfile"
    "docker-compose.yml"
    "deploy.sh"
    "healthcheck.sh"
)

# Add .env.example or env.template if available
if [ -f ".env.example" ]; then
    files_to_upload+=(".env.example")
elif [ -f "env.template" ]; then
    files_to_upload+=("env.template")
fi

for file in "${files_to_upload[@]}"; do
    if [ -f "$file" ]; then
        echo "  Uploading $file..."
        tsh scp "$file" "${SERVER_USER}@${SERVER_IP}:${DEPLOY_PATH}/"
        if [ $? -ne 0 ]; then
            echo "  WARNING: Failed to upload $file"
        fi
    else
        echo "  WARNING: File $file does not exist"
    fi
done
echo "OK Files uploaded"

# Step 5: Create .env file on server
echo ""
echo "[5/8] Creating .env file on server..."
read -sp "Enter OpenAI API Key: " api_key
echo
tsh ssh "${SERVER_USER}@${SERVER_IP}" "cd $DEPLOY_PATH && echo 'OPENAI_API_KEY=$api_key' > .env && chmod 600 .env"
if [ $? -ne 0 ]; then
    echo "ERROR: Cannot create .env file"
    exit 1
fi
echo "OK .env file created"

# Step 6: Set execute permissions for scripts
echo ""
echo "[6/8] Setting execute permissions for scripts..."
tsh ssh "${SERVER_USER}@${SERVER_IP}" "cd $DEPLOY_PATH && chmod +x deploy.sh healthcheck.sh"
if [ $? -ne 0 ]; then
    echo "ERROR: Cannot set permissions"
    exit 1
fi
echo "OK Permissions set"

# Step 7: Deploy on server
echo ""
echo "[7/8] Deploying on server..."
echo "Running deploy script on server..."
tsh ssh "${SERVER_USER}@${SERVER_IP}" "cd $DEPLOY_PATH && ./deploy.sh"
if [ $? -ne 0 ]; then
    echo "ERROR: Deployment failed"
    exit 1
fi

# Step 8: Health check
echo ""
echo "[8/8] Running health check..."
sleep 10
tsh ssh "${SERVER_USER}@${SERVER_IP}" "cd $DEPLOY_PATH && ./healthcheck.sh"

echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo ""
echo "Service deployed at:"
echo "  http://${SERVER_IP}:5000"
echo "  Health: http://${SERVER_IP}:5000/health"
echo ""
echo "To view logs:"
echo "  tsh ssh ${SERVER_USER}@${SERVER_IP} 'cd $DEPLOY_PATH && docker-compose logs -f'"

