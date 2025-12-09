# 🚀 Deploy Nhanh MLflow Gateway lên 10.3.49.202 (via Teleport)

## Yêu cầu trước khi deploy

1. **Cài đặt Teleport client**: Xem [TELEPORT_SETUP.md](TELEPORT_SETUP.md)
2. **Đăng nhập Teleport**: `tsh login --proxy=<teleport-proxy-address>`

## Phương Pháp 1: Script Tự Động (Khuyến nghị)

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

Script sẽ hỏi:
- Username Teleport
- OpenAI API Key

Sau đó tự động deploy và test.

---

## Phương Pháp 2: Deploy Thủ Công

### Bước 1: Tạo file .env
```powershell
cd "C:\Data_Mining\AI Gateway\mlflow-gateway"
echo "OPENAI_API_KEY=your_actual_api_key_here" > .env
```

### Bước 2: Upload files lên server qua Teleport
```powershell
$USER = "your_username"  # Thay bằng username Teleport của bạn
$IP = "10.3.49.202"
$PATH = "/opt/mlflow-gateway"

# Tạo thư mục
tsh ssh "${USER}@${IP}" "sudo mkdir -p $PATH && sudo chown `$USER:`$USER $PATH"

# Upload files
tsh scp config.yaml "${USER}@${IP}:${PATH}/"
tsh scp Dockerfile "${USER}@${IP}:${PATH}/"
tsh scp docker-compose.yml "${USER}@${IP}:${PATH}/"
tsh scp deploy.sh "${USER}@${IP}:${PATH}/"
tsh scp healthcheck.sh "${USER}@${IP}:${PATH}/"
tsh scp .env "${USER}@${IP}:${PATH}/"

# Cấp quyền
tsh ssh "${USER}@${IP}" "cd $PATH && chmod +x deploy.sh healthcheck.sh"
```

### Bước 3: Deploy trên server
```bash
# SSH vào server qua Teleport
tsh ssh your_username@10.3.49.202

# Deploy
cd /opt/mlflow-gateway
./deploy.sh
```

### Bước 4: Test
```powershell
# Từ máy local
.\test_remote.ps1
```

---

## Kiểm Tra Nhanh

```powershell
# Test health
Invoke-RestMethod -Uri "http://10.3.49.202:5000/health"

# Test API
$body = '{"messages":[{"role":"user","content":"test"}]}'
Invoke-RestMethod -Uri "http://10.3.49.202:5000/gateway/chat/invocations" -Method Post -Body $body -ContentType "application/json"
```

---

## Thông Tin Service

- **URL**: http://10.3.49.202:5000
- **Health**: http://10.3.49.202:5000/health
- **API**: http://10.3.49.202:5000/gateway/chat/invocations

---

## Troubleshooting

### Không kết nối được qua Teleport
```powershell
# Kiểm tra Teleport client
tsh version

# Kiểm tra login status
tsh status

# Test connection
tsh ssh user@10.3.49.202 "echo 'test'"
```

Xem thêm: [TELEPORT_SETUP.md](TELEPORT_SETUP.md)

### Xem logs trên server
```bash
tsh ssh user@10.3.49.202 "cd /opt/mlflow-gateway && docker-compose logs -f"
```

### Kiểm tra container
```bash
tsh ssh user@10.3.49.202 "docker ps | grep mlflow-gateway"
```





