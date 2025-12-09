# MLflow AI Gateway - Docker Deployment

Môi trường sẵn sàng deploy cho MLflow AI Gateway trên Windows (Docker Desktop + WSL2) và Linux server qua Teleport.

## Tổng Quan

MLflow AI Gateway cung cấp unified interface để quản lý và deploy multiple LLM providers (OpenAI, Anthropic, Azure OpenAI) thông qua một endpoint duy nhất.

**Thông tin Server:**
- Server: `adt-ml-dify-49-202` (10.3.49.202)
- Port: 5000
- Health Endpoint: `http://10.3.49.202:5000/health`
- API Endpoint: `http://10.3.49.202:5000/gateway/chat/invocations`

## Deploy Qua Teleport Web UI

### Bước 1: Truy cập Teleport Web UI

1. Đăng nhập vào Teleport Web UI
2. Tìm server `adt-ml-dify-49-202` trong phần Resources
3. Click "Connect" và chọn "Web Terminal"

### Bước 2: Kiểm tra Prerequisites

```bash
docker --version
docker compose version
git --version
```

Nếu thiếu, cài đặt:

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

### Bước 3: Clone Repository

```bash
cd /opt
sudo mkdir -p mlflow-gateway && sudo chown $USER:$USER mlflow-gateway
cd mlflow-gateway
git clone <your-repo-url> .
```

### Bước 4: Deploy

**Cách 1: Script Interactive (Khuyến nghị)**

```bash
chmod +x setup_and_deploy.sh
./setup_and_deploy.sh
```

**Cách 2: Script Đơn Giản**

```bash
cp env.template .env
nano .env  # Thêm: OPENAI_API_KEY=sk-your-actual-key-here
chmod +x deploy_web.sh
./deploy_web.sh
```

### Bước 5: Kiểm tra

```bash
docker ps --filter "name=mlflow-gateway"
curl http://localhost:5000/health
docker compose logs -f mlflow-gateway
```

### Bước 6: Test API

```bash
curl -X POST http://localhost:5000/gateway/chat/invocations \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello"}]}'
```

## Deploy Qua Teleport CLI

### Cài đặt Teleport Client

**Windows:**
```powershell
choco install teleport
```

**Linux/macOS:**
```bash
curl https://goteleport.com/static/install.sh | bash -s 13.4.15
```

### Đăng nhập và Deploy

```bash
tsh login --proxy=<teleport-proxy-address>
```

**Windows PowerShell:**
```powershell
.\deploy_to_server.ps1
```

**Linux/macOS:**
```bash
chmod +x teleport_deploy.sh
./teleport_deploy.sh [username]
```

## Local Development (Windows)

### Prerequisites

- Docker Desktop với WSL2 backend
- PowerShell 5.1+ hoặc PowerShell Core

### Quick Start

```powershell
# Tạo file .env
Copy-Item env.template .env
notepad .env  # Thêm API key

# Build và chạy
docker-compose build
docker-compose up -d

# Kiểm tra
docker ps --filter "name=mlflow-gateway"
.\healthcheck.ps1
```

## Quản Lý Service

```bash
# Xem logs
docker compose logs -f mlflow-gateway

# Dừng service
docker compose down

# Khởi động lại
docker compose restart

# Update và redeploy
git pull
docker compose down
docker compose build
docker compose up -d
```

## Troubleshooting

### Lỗi: Environment variable not set

```bash
# Kiểm tra file .env
cat .env

# Export biến và restart
export OPENAI_API_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d'=' -f2)
docker compose down
docker compose build --no-cache
OPENAI_API_KEY="$OPENAI_API_KEY" docker compose up -d
sleep 60
docker ps --filter "name=mlflow-gateway"
```

### Lỗi: Permission denied

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Lỗi: Port 5000 already in use

```bash
sudo lsof -i :5000
docker compose down
```

### Lỗi: API key invalid hoặc quota exceeded

```bash
# Test API key trực tiếp
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $(grep "^OPENAI_API_KEY=" .env | cut -d'=' -f2)"
```

Kiểm tra billing tại: https://platform.openai.com/account/billing

### Health check fails

```bash
sleep 60
curl http://localhost:5000/health
docker compose logs mlflow-gateway | tail -50
```

## Cấu Trúc Project

```
mlflow-gateway/
├── config.yaml              # MLflow Gateway config template
├── Dockerfile               # Container image definition
├── docker-compose.yml       # Docker Compose configuration
├── docker-compose.prod.yml  # Production configuration
├── env.template             # Environment variables template
├── .env                     # Actual environment variables (gitignored)
├── entrypoint.sh            # Container entrypoint script
├── deploy.sh                # Linux deploy script
├── deploy_web.sh            # Simple deploy script
├── setup_and_deploy.sh      # Interactive setup script
├── deploy_to_server.ps1     # PowerShell deploy script
├── teleport_deploy.sh       # Bash deploy script
├── healthcheck.ps1          # PowerShell health check
├── healthcheck.sh           # Bash health check
├── check_status.sh          # Status check script
└── README.md                # This file
```

## Security

**QUAN TRỌNG:** Không commit API keys hoặc secrets vào Git repository.

### Best Practices

- Sử dụng `.env` file (đã gitignore)
- Sử dụng environment variables
- Sử dụng secret management tools cho production (Vault, AWS Secrets Manager)
- Không hardcode API keys trong code
- Không commit .env file
- Không chia sẻ API keys qua chat/email

### Tạo file .env

```bash
cp env.template .env
nano .env  # Thêm: OPENAI_API_KEY=sk-your-actual-key-here
```

## Lệnh PowerShell

```powershell
# Build image
docker-compose build

# Chạy container
docker-compose up -d

# Kiểm tra status
docker ps --filter "name=mlflow-gateway"

# Xem logs
docker-compose logs -f mlflow-gateway

# Health check
.\healthcheck.ps1

# Test API
$body = '{"messages":[{"role":"user","content":"test"}]}'
Invoke-RestMethod -Uri "http://localhost:5000/gateway/chat/invocations" -Method Post -Body $body -ContentType "application/json"

# Dừng container
docker-compose down
```

## Acceptance Criteria

- Container `mlflow-gateway` đang chạy với status "Up"
- Health endpoint trả về `{"status":"OK"}`
- API endpoint trả về JSON hợp lệ từ LLM provider
- Logs không có errors về "Environment variable not set"

## Service URLs

- Service: `http://10.3.49.202:5000`
- Health: `http://10.3.49.202:5000/health`
- API: `http://10.3.49.202:5000/gateway/chat/invocations`
