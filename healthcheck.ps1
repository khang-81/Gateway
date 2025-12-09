# MLflow Gateway Health Check Script (PowerShell)
# Tests the chat endpoint and validates response

$url = "http://localhost:5000/gateway/chat/invocations"
$body = @{
    messages = @(
        @{
            role = "user"
            content = "health check"
        }
    )
} | ConvertTo-Json -Depth 10

try {
    Write-Host "Sending health check request to $url..." -ForegroundColor Cyan
    
    $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    
    # Check if response contains choices or output field
    if ($response.choices -or $response.output -or $response.candidates) {
        Write-Host "Health check PASSED" -ForegroundColor Green
        Write-Host "Response:" -ForegroundColor Yellow
        $response | ConvertTo-Json -Depth 10
        exit 0
    } else {
        Write-Host "Health check FAILED: Response missing expected fields" -ForegroundColor Red
        Write-Host "Response:" -ForegroundColor Yellow
        $response | ConvertTo-Json -Depth 10
        exit 1
    }
} catch {
    Write-Host "Health check FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "Error details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    exit 1
}

