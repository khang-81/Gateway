# Script Deploy MLflow Gateway len Server 10.3.49.202 via Teleport
# Chay script nay tu may Windows local
# Yeu cau: Teleport client (tsh) da duoc cai dat va dang login

$SERVER_IP = "10.3.49.202"
$SERVER_USER = Read-Host "Nhap username de SSH vao server qua Teleport (vi du: root, ubuntu, admin)"
$DEPLOY_PATH = "/opt/mlflow-gateway"

Write-Host "`n=== MLflow Gateway Deployment Script (Teleport) ===" -ForegroundColor Cyan
Write-Host "Server: $SERVER_IP" -ForegroundColor Yellow
Write-Host "Deploy path: $DEPLOY_PATH`n" -ForegroundColor Yellow

# Buoc 0: Kiem tra Teleport client
Write-Host "[0/8] Kiem tra Teleport client (tsh)..." -ForegroundColor Green
$tshCheck = Get-Command tsh -ErrorAction SilentlyContinue
if (-not $tshCheck) {
    Write-Host "ERROR: Teleport client (tsh) chua duoc cai dat" -ForegroundColor Red
    Write-Host "Vui long cai dat Teleport client:" -ForegroundColor Yellow
    Write-Host "  Windows: Download tu https://goteleport.com/docs/installation/" -ForegroundColor Yellow
    Write-Host "  Hoac: choco install teleport" -ForegroundColor Yellow
    exit 1
}
Write-Host "OK Teleport client da duoc cai dat" -ForegroundColor Green

# Buoc 1: Kiem tra Teleport login status
Write-Host "`n[1/8] Kiem tra Teleport login status..." -ForegroundColor Green
$tshStatus = tsh status 2>&1
if ($LASTEXITCODE -ne 0 -or $tshStatus -match "Not logged in") {
    Write-Host "WARNING: Chua login vao Teleport" -ForegroundColor Yellow
    Write-Host "Vui long login vao Teleport truoc:" -ForegroundColor Yellow
    Write-Host "  tsh login --proxy=<teleport-proxy-address>" -ForegroundColor Cyan
    $continue = Read-Host "Ban co muon tiep tuc? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
} else {
    Write-Host "OK Da login vao Teleport" -ForegroundColor Green
    Write-Host $tshStatus -ForegroundColor Cyan
}

# Buoc 2: Kiem tra ket noi den server qua Teleport
Write-Host "`n[2/8] Kiem tra ket noi den server qua Teleport..." -ForegroundColor Green
$testConnection = tsh ssh -o ConnectTimeout=5 "${SERVER_USER}@${SERVER_IP}" "echo 'Connection test'" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Khong the ket noi den $SERVER_IP qua Teleport" -ForegroundColor Red
    Write-Host "Vui long kiem tra:" -ForegroundColor Yellow
    Write-Host "  - Teleport proxy dang chay" -ForegroundColor Yellow
    Write-Host "  - Ban co quyen truy cap server $SERVER_IP" -ForegroundColor Yellow
    Write-Host "  - Username $SERVER_USER la dung" -ForegroundColor Yellow
    exit 1
}
Write-Host "OK Ket noi thanh cong qua Teleport" -ForegroundColor Green

# Buoc 3: Tao thu muc tren server
Write-Host "`n[3/8] Tao thu muc tren server..." -ForegroundColor Green
tsh ssh "${SERVER_USER}@${SERVER_IP}" "sudo mkdir -p $DEPLOY_PATH && sudo chown `$USER:`$USER $DEPLOY_PATH"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Khong the tao thu muc tren server" -ForegroundColor Red
    exit 1
}
Write-Host "OK Thu muc da duoc tao" -ForegroundColor Green

# Buoc 4: Upload files
Write-Host "`n[4/8] Upload files len server qua Teleport..." -ForegroundColor Green
$filesToUpload = @(
    "config.yaml",
    "Dockerfile",
    "docker-compose.yml",
    "deploy.sh",
    "healthcheck.sh"
)

# Add .env.example or env.template if available
if (Test-Path ".env.example") {
    $filesToUpload += ".env.example"
} elseif (Test-Path "env.template") {
    $filesToUpload += "env.template"
}

foreach ($file in $filesToUpload) {
    if (Test-Path $file) {
        Write-Host "  Uploading $file..." -ForegroundColor Cyan
        tsh scp $file "${SERVER_USER}@${SERVER_IP}:${DEPLOY_PATH}/"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  WARNING: Upload $file that bai" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  WARNING: File $file khong ton tai" -ForegroundColor Yellow
    }
}
Write-Host "OK Files da duoc upload" -ForegroundColor Green

# Buoc 5: Tao file .env tren server
Write-Host "`n[5/8] Tao file .env tren server..." -ForegroundColor Green
Write-Host "Vui long nhap OpenAI API Key:" -ForegroundColor Yellow
$apiKey = Read-Host "OPENAI_API_KEY" -AsSecureString
$apiKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
)

tsh ssh "${SERVER_USER}@${SERVER_IP}" "cd $DEPLOY_PATH && echo 'OPENAI_API_KEY=$apiKeyPlain' > .env && chmod 600 .env"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Khong the tao file .env" -ForegroundColor Red
    exit 1
}
Write-Host "OK File .env da duoc tao" -ForegroundColor Green

# Buoc 6: Cap quyen thuc thi cho scripts
Write-Host "`n[6/8] Cap quyen thuc thi cho scripts..." -ForegroundColor Green
tsh ssh "${SERVER_USER}@${SERVER_IP}" "cd $DEPLOY_PATH && chmod +x deploy.sh healthcheck.sh"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Khong the cap quyen" -ForegroundColor Red
    exit 1
}
Write-Host "OK Quyen da duoc cap" -ForegroundColor Green

# Buoc 7: Deploy tren server
Write-Host "`n[7/8] Deploy tren server..." -ForegroundColor Green
Write-Host "Dang chay deploy script tren server..." -ForegroundColor Cyan
tsh ssh "${SERVER_USER}@${SERVER_IP}" "cd $DEPLOY_PATH && ./deploy.sh"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Deploy that bai" -ForegroundColor Red
    exit 1
}

# Buoc 8: Kiem tra health
Write-Host "`n[8/8] Kiem tra health..." -ForegroundColor Green
Start-Sleep -Seconds 10
tsh ssh "${SERVER_USER}@${SERVER_IP}" "cd $DEPLOY_PATH && ./healthcheck.sh"

Write-Host "`n=== DEPLOYMENT HOAN TAT ===" -ForegroundColor Green
Write-Host "`nService da duoc deploy tai:" -ForegroundColor Cyan
Write-Host "  http://${SERVER_IP}:5000" -ForegroundColor Yellow
Write-Host "  Health: http://${SERVER_IP}:5000/health" -ForegroundColor Yellow
Write-Host "`nDe xem logs:" -ForegroundColor Cyan
Write-Host "  tsh ssh ${SERVER_USER}@${SERVER_IP} `"cd $DEPLOY_PATH && docker-compose logs -f`"" -ForegroundColor Yellow
