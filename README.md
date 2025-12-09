# MLflow AI Gateway - Docker Deployment

Môi trường dev sẵn sàng deploy cho MLflow AI Gateway trên Windows (Docker Desktop + WSL2) và Linux server.

## 🚀 Quick Deploy Options

- **🚀 Quick Start**: [QUICK_START.md](QUICK_START.md) - Hướng dẫn deploy nhanh nhất
- **📖 Hướng dẫn đầy đủ**: [DEPLOY_GUIDE.md](DEPLOY_GUIDE.md) - Step-by-step guide chi tiết
- **Teleport Web UI** (Khuyến nghị): Deploy trực tiếp qua Web Terminal - không cần cài đặt client. Xem [DEPLOY_WEB_UI.md](DEPLOY_WEB_UI.md)
- **Teleport CLI**: Deploy qua command line với `tsh`. Xem [DEPLOY_STEPS.md](DEPLOY_STEPS.md)
- **Local Development**: Chạy trên máy local với Docker Desktop. Xem phần Quick Start bên dưới

## Prerequisites (Windows)

- Docker Desktop với WSL2 backend
- PowerShell 5.1+ hoặc PowerShell Core
- WSL2 đã cài đặt và kích hoạt

## Quick Start (Windows)

### 1. Chuẩn bị môi trường

```powershell
# Copy file env.template thành .env và điền API key
Copy-Item env.template .env
# Hoặc nếu có .env.example: Copy-Item .env.example .env
# Mở .env và thay your_key_here bằng OpenAI API key thực tế
```

### 2. Build và chạy

```powershell
# Build image
docker-compose build

# Chạy container (detached mode)
docker-compose up -d

# Kiểm tra container status
docker ps --filter "name=mlflow-gateway"

# Xem logs
docker-compose logs -f mlflow-gateway
```

### 3. Test endpoint

```powershell
# Health check script
.\healthcheck.ps1

# Hoặc test thủ công với curl
$body = @{
    messages = @(
        @{
            role = "user"
            content = "Hello, how are you?"
        }
    )
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "http://localhost:5000/gateway/chat/invocations" -Method Post -Body $body -ContentType "application/json"
```

## Deploy lên Linux Server

### Phương Pháp 1: Deploy qua Teleport Web UI (Khuyến nghị)

Deploy trực tiếp qua Web Terminal trong Teleport Web UI - không cần cài đặt Teleport client.

**Bước 1**: Truy cập Teleport Web UI và click "Connect" vào server `adt-ml-dify-49-202`

**Bước 2**: Mở Web Terminal

**Bước 3**: Clone repository và chạy script:

```bash
cd /opt
sudo mkdir -p mlflow-gateway && sudo chown $USER:$USER mlflow-gateway
cd mlflow-gateway
git clone <your-repo-url> .
chmod +x setup_and_deploy.sh
./setup_and_deploy.sh
```

Script sẽ hướng dẫn bạn qua toàn bộ quá trình setup và deploy.

**Xem hướng dẫn chi tiết**: [DEPLOY_WEB_UI.md](DEPLOY_WEB_UI.md)

### Phương Pháp 2: Deploy qua Teleport CLI

#### Yêu cầu
- Teleport client (tsh) đã cài đặt và đăng nhập
- Xem hướng dẫn: [TELEPORT_SETUP.md](TELEPORT_SETUP.md)

#### Deploy tự động

**Windows PowerShell:**
```powershell
.\deploy_to_server.ps1
```

**Linux/macOS Bash:**
```bash
chmod +x teleport_deploy.sh
./teleport_deploy.sh [username]
```

#### Deploy thủ công

1. Copy toàn bộ thư mục `mlflow-gateway/` lên server qua Teleport
2. Tạo file `.env` từ `env.template` và điền API key
3. SSH vào server qua Teleport và chạy script deploy:

```bash
tsh ssh user@10.3.49.202
cd /opt/mlflow-gateway
chmod +x deploy.sh healthcheck.sh
./deploy.sh
```

4. Kiểm tra health:

```bash
./healthcheck.sh
```

Xem chi tiết: [DEPLOY_STEPS.md](DEPLOY_STEPS.md)

## Production Hardening

### 1. TLS/SSL với Nginx và Let's Encrypt

- Cài đặt Nginx reverse proxy trước MLflow Gateway
- Sử dụng Certbot để lấy Let's Encrypt certificate
- Cấu hình Nginx với SSL termination
- Redirect HTTP → HTTPS

**Ví dụ nginx.conf:**
```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    location / {
        proxy_pass http://mlflow-gateway:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 2. Secret Management

**Option A: Docker Secrets (Docker Swarm)**
```yaml
secrets:
  openai_api_key:
    external: true

services:
  mlflow-gateway:
    secrets:
      - openai_api_key
    environment:
      OPENAI_API_KEY_FILE: /run/secrets/openai_api_key
```

**Option B: HashiCorp Vault**
- Mount Vault agent vào container
- Inject secrets qua Vault Agent Sidecar
- Rotate keys định kỳ

**Option C: AWS Secrets Manager / Azure Key Vault**
- Sử dụng SDK để fetch secrets tại runtime
- Cache secrets trong memory (không ghi vào disk)

### 3. Logging & Audit

- **Centralized Logging**: Gửi logs tới ELK stack, Loki, hoặc CloudWatch
- **Log Retention**: Giữ logs tối thiểu 30-90 ngày
- **Audit Trail**: Log tất cả API requests/responses (PII masking)
- **Monitoring**: Prometheus + Grafana cho metrics

**Ví dụ docker-compose logging:**
```yaml
services:
  mlflow-gateway:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## Cấu trúc Project

```
mlflow-gateway/
├── config.yaml              # MLflow Gateway configuration (chuẩn MLflow: endpoints, endpoint_type)
├── Dockerfile               # Container image definition
├── docker-compose.yml       # Docker Compose configuration
├── docker-compose.prod.yml  # Production Docker Compose configuration
├── env.template             # Environment variables template
├── .env                     # Actual environment variables (gitignored, tạo từ env.template)
├── deploy.sh                # Linux deploy script (chạy trên server)
├── deploy_web.sh            # Simple deploy script for Web Terminal
├── setup_and_deploy.sh      # Interactive setup and deploy script for Web Terminal
├── deploy_to_server.ps1     # PowerShell deploy script (Teleport CLI)
├── teleport_deploy.sh       # Bash deploy script (Teleport CLI)
├── healthcheck.ps1          # PowerShell health check
├── healthcheck.sh           # Bash health check
├── check_status.sh          # Status check script
├── README.md                # Main documentation
├── DEPLOY_GUIDE.md          # Hướng dẫn deploy đầy đủ step-by-step
├── DEPLOY_WEB_UI.md         # Hướng dẫn deploy qua Teleport Web UI
├── DEPLOY_STEPS.md          # Chi tiết hướng dẫn deploy (CLI)
├── TELEPORT_SETUP.md        # Teleport CLI setup guide
├── TROUBLESHOOTING.md       # Troubleshooting guide
└── SECURITY.md              # Security best practices
```

## Lệnh PowerShell Chính Xác (Copy-Paste)

```powershell
# 1. Build image
docker-compose build

# 2. Chạy container (detached)
docker-compose up -d

# 3. Kiểm tra container status
docker ps --filter "name=mlflow-gateway"

# 4. Xem logs
docker-compose logs -f mlflow-gateway

# 5. Chạy healthcheck
.\healthcheck.ps1

# 6. Test curl thủ công
$body = '{"messages":[{"role":"user","content":"test"}]}'
Invoke-RestMethod -Uri "http://localhost:5000/gateway/chat/invocations" -Method Post -Body $body -ContentType "application/json"

# 7. Dừng container
docker-compose down

# 8. Xóa image và container
docker-compose down --rmi all
```

## Acceptance Criteria

- ✅ `docker ps` hiển thị container `mlflow-gateway` đang chạy
- ✅ `curl` test trả về JSON hợp lệ từ LLM provider proxy
- ✅ Healthcheck script trả về exit code 0

## Troubleshooting

- **Container không start**: Kiểm tra `.env` file có đúng format không
- **Connection refused**: Đảm bảo port 5000 không bị chiếm bởi service khác
- **API key invalid**: Verify API key trong `.env` file
- **Healthcheck fails**: Đợi container khởi động hoàn toàn (30-40 giây)

