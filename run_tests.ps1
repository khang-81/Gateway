# MLflow Gateway Test Runner (PowerShell)

Write-Host "============================================================"
Write-Host "MLflow Gateway Test Runner"
Write-Host "============================================================"

# Check if Python is available
if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "Running Python test script..."
    python test_api.py
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    Write-Host "Running Python test script..."
    python3 test_api.py
} else {
    Write-Host "Python not found. Please install Python to run tests."
    exit 1
}

Write-Host ""
Write-Host "============================================================"
Write-Host "Cost Tracking"
Write-Host "============================================================"

# Track costs from Docker logs
if (Get-Command python -ErrorAction SilentlyContinue) {
    python track_costs.py --container mlflow-gateway
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    python3 track_costs.py --container mlflow-gateway
} else {
    Write-Host "Python not found. Cannot track costs."
}

