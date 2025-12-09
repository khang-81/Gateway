# Script Test MLflow Gateway trên Server 10.3.49.202
# Chạy từ máy Windows local

$SERVER_IP = "10.3.49.202"
$BASE_URL = "http://${SERVER_IP}:5000"

Write-Host "`n=== Testing MLflow Gateway trên $SERVER_IP ===" -ForegroundColor Cyan

# Test 1: Health Check
Write-Host "`n[1/3] Testing Health Endpoint..." -ForegroundColor Green
try {
    $healthResponse = Invoke-RestMethod -Uri "${BASE_URL}/health" -Method Get -ErrorAction Stop
    Write-Host "✓ Health check PASSED" -ForegroundColor Green
    $healthResponse | ConvertTo-Json
} catch {
    Write-Host "✗ Health check FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Kiểm tra:" -ForegroundColor Yellow
    Write-Host "    - Container đang chạy: ssh user@$SERVER_IP 'docker ps | grep mlflow-gateway'" -ForegroundColor Yellow
    Write-Host "    - Port 5000 đã được mở trong firewall" -ForegroundColor Yellow
    exit 1
}

# Test 2: Chat Endpoint
Write-Host "`n[2/3] Testing Chat Endpoint..." -ForegroundColor Green
$chatBody = @{
    messages = @(
        @{
            role = "user"
            content = "Hello, this is a test message"
        }
    )
} | ConvertTo-Json -Depth 10

try {
    Write-Host "Sending request..." -ForegroundColor Cyan
    $chatResponse = Invoke-RestMethod -Uri "${BASE_URL}/gateway/chat/invocations" -Method Post -Body $chatBody -ContentType "application/json" -ErrorAction Stop
    
    Write-Host "✓ Chat endpoint PASSED" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Yellow
    $chatResponse | ConvertTo-Json -Depth 10
} catch {
    Write-Host "✗ Chat endpoint FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "Error details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    Write-Host "  Kiểm tra:" -ForegroundColor Yellow
    Write-Host "    - API key trong file .env trên server" -ForegroundColor Yellow
    Write-Host "    - Outbound access đến api.openai.com" -ForegroundColor Yellow
    exit 1
}

# Test 3: Container Status
Write-Host "`n[3/3] Checking Container Status..." -ForegroundColor Green
Write-Host "Để kiểm tra container status, chạy lệnh sau:" -ForegroundColor Cyan
Write-Host "  ssh user@$SERVER_IP 'cd /opt/mlflow-gateway && docker ps --filter name=mlflow-gateway'" -ForegroundColor Yellow

Write-Host "`n=== ALL TESTS COMPLETED ===" -ForegroundColor Green
Write-Host "`nService URL: $BASE_URL" -ForegroundColor Cyan
Write-Host "Health: ${BASE_URL}/health" -ForegroundColor Cyan
Write-Host "API: ${BASE_URL}/gateway/chat/invocations" -ForegroundColor Cyan





