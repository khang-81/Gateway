# Hướng Dẫn Deploy MLflow Gateway qua Teleport Web UI

Hướng dẫn chi tiết để deploy MLflow AI Gateway lên server `adt-ml-dify-49-202` (10.3.49.202) sử dụng Teleport Web Terminal.

## Yêu Cầu Trước Khi Bắt Đầu

1. **Truy cập Teleport Web UI**: Bạn cần có quyền truy cập vào Teleport Web UI
2. **Git Repository**: Code đã được push lên Git repository (GitHub, GitLab, hoặc internal Git)
3. **OpenAI API Key**: Cần có API key để cấu hình gateway

## Bước 1: Truy Cập Teleport Web UI

1. Mở trình duyệt và truy cập Teleport Web UI
2. Đăng nhập với credentials của bạn
3. Trong phần **Resources**, tìm server `adt-ml-dify-49-202` (IP: 10.3.49.202)
4. Click vào nút **"Connect"** (có dropdown arrow)

## Bước 2: Mở Web Terminal

1. Từ dropdown menu của nút "Connect", chọn **"Web Terminal"** hoặc **"Terminal"**
2. Web Terminal sẽ mở trong trình duyệt
3. Bạn sẽ thấy shell prompt, thường là: `user@adt-ml-dify-49-202:~$`

## Bước 3: Chuẩn Bị Môi Trường

### Kiểm tra prerequisites

```bash
# Kiểm tra Docker
docker --version
docker info

# Kiểm tra docker-compose
docker compose version
# hoặc
docker-compose --version

# Kiểm tra Git
git --version
```

Nếu thiếu bất kỳ tool nào, cài đặt:

```bash
# Cài Docker (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y docker.io docker-compose git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
# Logout và login lại để áp dụng group changes

# Cài Git (nếu chưa có)
sudo apt-get install -y git
```

## Bước 4: Clone Repository

### Phương pháp 1: Sử dụng script tự động (Khuyến nghị)

```bash
# Di chuyển đến thư mục làm việc
cd /opt
sudo mkdir -p mlflow-gateway
sudo chown $USER:$USER mlflow-gateway
cd mlflow-gateway

# Clone repository (thay <repo-url> bằng URL thực tế)
git clone <repo-url> .

# Hoặc nếu repository có thư mục con
git clone <repo-url> temp
mv temp/mlflow-gateway/* .
rm -rf temp
```

### Phương pháp 2: Clone vào thư mục cụ thể

```bash
cd ~
git clone <repo-url> mlflow-gateway
cd mlflow-gateway
```

**Lưu ý**: Thay `<repo-url>` bằng URL Git repository thực tế của bạn, ví dụ:
- `https://github.com/username/mlflow-gateway.git`
- `git@github.com:username/mlflow-gateway.git`
- Hoặc internal Git server URL

## Bước 5: Deploy

### Phương pháp 1: Sử dụng script tự động (Khuyến nghị)

Script `setup_and_deploy.sh` sẽ hướng dẫn bạn qua toàn bộ quá trình:

```bash
# Đảm bảo script có quyền thực thi
chmod +x setup_and_deploy.sh

# Chạy script
./setup_and_deploy.sh
```

Script sẽ:
1. Kiểm tra prerequisites
2. Hỏi Git repository URL (nếu chưa clone)
3. Hỏi OpenAI API Key
4. Tạo file .env
5. Build và start container
6. Verify deployment

### Phương pháp 2: Deploy thủ công

Nếu đã có repository và .env file:

```bash
# Đảm bảo script có quyền thực thi
chmod +x deploy_web.sh

# Chạy deploy
./deploy_web.sh
```

### Phương pháp 3: Deploy từng bước thủ công

```bash
# 1. Tạo file .env từ template
cp env.template .env

# 2. Chỉnh sửa .env và thêm API key
nano .env
# Hoặc
vi .env
# Thêm: OPENAI_API_KEY=sk-your-actual-key-here

# 3. Build và start
docker compose build
docker compose up -d

# 4. Kiểm tra status
docker ps --filter "name=mlflow-gateway"

# 5. Xem logs
docker compose logs -f mlflow-gateway
```

## Bước 6: Kiểm Tra Deployment

### Kiểm tra container status

```bash
docker ps --filter "name=mlflow-gateway"
```

Kết quả mong đợi: Container `mlflow-gateway` đang chạy với status "Up"

### Kiểm tra health endpoint

```bash
curl http://localhost:5000/health
```

Kết quả mong đợi: JSON response với status

### Kiểm tra API endpoint

```bash
curl -X POST http://localhost:5000/gateway/chat/invocations \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello"}]}'
```

Kết quả mong đợi: JSON response từ OpenAI API

### Xem logs

```bash
docker compose logs -f mlflow-gateway
```

Nhấn `Ctrl+C` để thoát khỏi log view.

## Bước 7: Truy Cập Service

Sau khi deploy thành công, service sẽ chạy tại:

- **Local (trên server)**: `http://localhost:5000`
- **Từ network**: `http://10.3.49.202:5000` (nếu firewall cho phép)

### Endpoints

- **Health**: `http://10.3.49.202:5000/health`
- **API**: `http://10.3.49.202:5000/gateway/chat/invocations`

## Quản Lý Service

### Xem logs

```bash
docker compose logs -f mlflow-gateway
```

### Dừng service

```bash
docker compose down
```

### Khởi động lại service

```bash
docker compose restart
# hoặc
docker compose down
docker compose up -d
```

### Xem status

```bash
docker ps --filter "name=mlflow-gateway"
docker compose ps
```

### Update và redeploy

```bash
# Pull code mới
git pull

# Rebuild và restart
docker compose down
docker compose build
docker compose up -d
```

## Troubleshooting

### Lỗi: "Permission denied" khi chạy Docker

```bash
# Thêm user vào docker group
sudo usermod -aG docker $USER

# Logout và login lại Teleport Web Terminal
# Hoặc
newgrp docker
```

### Lỗi: "Cannot connect to Docker daemon"

```bash
# Kiểm tra Docker service
sudo systemctl status docker

# Khởi động Docker nếu cần
sudo systemctl start docker
```

### Lỗi: "Port 5000 already in use"

```bash
# Kiểm tra process đang dùng port 5000
sudo lsof -i :5000
# hoặc
sudo netstat -tulpn | grep 5000

# Dừng process hoặc đổi port trong docker-compose.yml
```

### Lỗi: "API key invalid"

```bash
# Kiểm tra file .env
cat .env

# Đảm bảo không có khoảng trắng thừa
# Format đúng: OPENAI_API_KEY=sk-...

# Test API key trực tiếp
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Container không start

```bash
# Xem logs chi tiết
docker compose logs mlflow-gateway

# Kiểm tra config
cat config.yaml
cat .env

# Rebuild từ đầu
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Health check fails

```bash
# Đợi thêm thời gian (container cần 30-40 giây để khởi động)
sleep 30

# Kiểm tra lại
curl http://localhost:5000/health

# Xem logs để tìm lỗi
docker compose logs mlflow-gateway | tail -50
```

## Lưu Ý Bảo Mật

1. **File .env**: Không commit file `.env` vào Git
2. **API Keys**: Giữ bí mật API keys, không chia sẻ
3. **Firewall**: Cấu hình firewall để chỉ cho phép truy cập từ network cần thiết
4. **Permissions**: Đảm bảo file `.env` có permission 600: `chmod 600 .env`

## Tài Liệu Tham Khảo

- [README.md](README.md) - Hướng dẫn tổng quan
- [DEPLOY_STEPS.md](DEPLOY_STEPS.md) - Hướng dẫn deploy chi tiết
- [QUICK_DEPLOY.md](QUICK_DEPLOY.md) - Deploy nhanh
- [TELEPORT_SETUP.md](TELEPORT_SETUP.md) - Setup Teleport client
- [MLflow AI Gateway Documentation](https://mlflow.org/docs/latest/genai/governance/ai-gateway/)

## Hỗ Trợ

Nếu gặp vấn đề, kiểm tra:
1. Logs: `docker compose logs mlflow-gateway`
2. Container status: `docker ps --filter name=mlflow-gateway`
3. Health endpoint: `curl http://localhost:5000/health`
4. Network connectivity: `ping 10.3.49.202`

