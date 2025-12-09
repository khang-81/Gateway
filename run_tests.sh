#!/bin/bash
# MLflow Gateway Test Runner

set -e

echo "============================================================"
echo "MLflow Gateway Test Runner"
echo "============================================================"

# Check if Python is available
if command -v python3 &> /dev/null; then
    echo "Running Python test script..."
    python3 test_api.py
elif command -v python &> /dev/null; then
    echo "Running Python test script..."
    python test_api.py
else
    echo "Python not found, running Bash test script..."
    chmod +x test_api.sh
    ./test_api.sh
fi

echo ""
echo "============================================================"
echo "Cost Tracking"
echo "============================================================"

# Track costs from Docker logs
if command -v python3 &> /dev/null; then
    python3 track_costs.py --container mlflow-gateway
elif command -v python &> /dev/null; then
    python track_costs.py --container mlflow-gateway
else
    echo "Python not found. Cannot track costs."
    echo "Install Python to use cost tracking feature."
fi

