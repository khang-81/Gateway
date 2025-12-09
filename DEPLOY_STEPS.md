# Hướng Dẫn Deploy MLflow Gateway lên Server 10.3.49.202 (via Teleport)

## Yêu cầu trước khi deploy

1. **Cài đặt Teleport client (tsh)**: Xem hướng dẫn trong [TELEPORT_SETUP.md](TELEPORT_SETUP.md)
2. **Đăng nhập vào Teleport**: `tsh login --proxy=<teleport-proxy-address>`
3. **Kiểm tra kết nối**: `tsh ssh user@10.3.49.202 "echo 'test'"`

## Phương Pháp 1: Deploy Tự Động (Khuyến nghị)

### Windows PowerShell
```powershell
cd "C:\Data_Mining\AI Gateway\mlflow-gateway"
.\deploy_to_server.ps1
```

### Linux/macOS Bash
```bash
cd /path/to/mlflow-gateway
chmod +x teleport_deploy.sh
./teleport_deploy.sh [username]
```

Script sẽ tự động:
- Kiểm tra Teleport client và login status
- Kiểm tra kết nối đến server qua Teleport
- Upload files lên server
- Tạo file .env
- Deploy và kiểm tra health

---

## Phương Pháp 2: Deploy Thủ Công

### Bước 1: Chuẩn bị files
Đảm bảo các file sau có trong thư mục `mlflow-gateway/`:
- config.yaml
- Dockerfile
- docker-compose.yml
- deploy.sh
- healthcheck.sh
- env.template (hoặc .env.example)

### Bước 2: Tạo file .env
```powershell
# Copy template
if (Test-Path "env.template") {
    Copy-Item env.template .env
} elseif (Test-Path ".env.example") {
    Copy-Item .env.example .env
}

# Mở file .env và thay your_key_here bằng OpenAI API key thực tế
notepad .env
```

### Bước 3: Upload files lên server qua Teleport
```powershell
# Thay USERNAME bằng username Teleport của bạn
$SERVER_USER = "your_username"
$SERVER_IP = "10.3.49.202"
$DEPLOY_PATH = "/opt/mlflow-gateway"

# Tạo thư mục trên server
tsh ssh "${SERVER_USER}@${SERVER_IP}" "sudo mkdir -p $DEPLOY_PATH && sudo chown `$USER:`$USER $DEPLOY_PATH"

# Upload files
tsh scp config.yaml "${SERVER_USER}@${SERVER_IP}:${DEPLOY_PATH}/"
tsh scp Dockerfile "${SERVER_USER}@${SERVER_IP}:${DEPLOY_PATH}/"
tsh scp docker-compose.yml "${SERVER_USER}@${SERVER_IP}:${DEPLOY_PATH}/"
tsh scp deploy.sh "${SERVER_USER}@${SERVER_IP}:${DEPLOY_PATH}/"
tsh scp healthcheck.sh "${SERVER_USER}@${SERVER_IP}:${DEPLOY_PATH}/"
tsh scp .env "${SERVER_USER}@${SERVER_IP}:${DEPLOY_PATH}/"

# Cấp quyền thực thi
tsh ssh "${SERVER_USER}@${SERVER_IP}" "cd $DEPLOY_PATH && chmod +x deploy.sh healthcheck.sh"
```

### Bước 4: SSH vào server qua Teleport và deploy
```bash
# SSH vào server qua Teleport
tsh ssh your_username@10.3.49.202

# Di chuyển vào thư mục
cd /opt/mlflow-gateway

# Kiểm tra files
ls -la

# Chạy deploy script
./deploy.sh
```

### Bước 5: Kiểm tra deployment
```bash
# Kiểm tra container status
docker ps --filter "name=mlflow-gateway"

# Xem logs
docker-compose logs -f mlflow-gateway

# Chạy healthcheck
./healthcheck.sh
```

### Bước 6: Test từ máy local
```powershell
# Test health endpoint
Invoke-RestMethod -Uri "http://10.3.49.202:5000/health" -Method Get

# Test chat endpoint
$body = '{"messages":[{"role":"user","content":"Hello"}]}'
Invoke-RestMethod -Uri "http://10.3.49.202:5000/gateway/chat/invocations" -Method Post -Body $body -ContentType "application/json"
```

---

## Troubleshooting

### Lỗi: Không thể kết nối qua Teleport
- Kiểm tra Teleport client đã cài đặt: `tsh version`
- Kiểm tra đã login: `tsh status`
- Kiểm tra kết nối: `tsh ssh user@10.3.49.202 "echo 'test'"`
- Xem thêm: [TELEPORT_SETUP.md](TELEPORT_SETUP.md)

### Lỗi: Permission denied
```bash
# Cấp quyền cho user
sudo usermod -aG docker $USER
# Logout và login lại
```

### Lỗi: Port 5000 đã được sử dụng
```bash
# Kiểm tra process đang dùng port 5000
sudo lsof -i :5000
# Hoặc đổi port trong docker-compose.yml
```

### Lỗi: Docker không chạy
```bash
# Kiểm tra Docker service
sudo systemctl status docker
# Khởi động Docker
sudo systemctl start docker
```

### Lỗi: API key không hợp lệ
- Kiểm tra file .env trên server
- Đảm bảo không có khoảng trắng thừa
- Test API key trực tiếp với OpenAI

---

## Kiểm Tra Sau Deploy

### Checklist
- [ ] Container đang chạy: `docker ps | grep mlflow-gateway`
- [ ] Health check pass: `curl http://10.3.49.202:5000/health`
- [ ] API endpoint trả về response: Test với curl hoặc PowerShell
- [ ] Logs không có errors: `docker-compose logs mlflow-gateway`
- [ ] Port 5000 accessible từ network

---

## Lệnh Quản Lý (via Teleport)

### Xem logs
```bash
tsh ssh user@10.3.49.202 "cd /opt/mlflow-gateway && docker-compose logs -f"
```

### Dừng service
```bash
tsh ssh user@10.3.49.202 "cd /opt/mlflow-gateway && docker-compose down"
```

### Khởi động lại service
```bash
tsh ssh user@10.3.49.202 "cd /opt/mlflow-gateway && docker-compose restart"
```

### Update và redeploy
```bash
# Upload files mới qua Teleport
tsh scp config.yaml user@10.3.49.202:/opt/mlflow-gateway/
tsh scp docker-compose.yml user@10.3.49.202:/opt/mlflow-gateway/

# SSH vào server qua Teleport và rebuild
tsh ssh user@10.3.49.202
cd /opt/mlflow-gateway
docker-compose down
docker-compose build
docker-compose up -d
```

---

## Thông Tin Service

- **Server IP**: 10.3.49.202
- **Port**: 5000
- **Health Endpoint**: http://10.3.49.202:5000/health
- **API Endpoint**: http://10.3.49.202:5000/gateway/chat/invocations
- **Deploy Path**: /opt/mlflow-gateway





