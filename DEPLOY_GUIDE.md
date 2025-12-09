# 🚀 Hướng Dẫn Deploy MLflow Gateway - Step by Step

Hướng dẫn chi tiết từng bước để deploy MLflow AI Gateway lên server 10.3.49.202 qua Teleport Web UI.

## 📋 Chuẩn Bị Trước Khi Deploy

### 1. Thông tin cần có
- ✅ Truy cập Teleport Web UI
- ✅ Git repository URL (nơi chứa code mlflow-gateway)
- ✅ OpenAI API Key

### 2. Kiểm tra server
- Server: `adt-ml-dify-49-202` (IP: 10.3.49.202)
- Port: 5000 (sẽ được expose)

---

## 🎯 Phương Pháp 1: Deploy Qua Teleport Web UI (Khuyến nghị)

### Bước 1: Truy cập Teleport Web UI

1. Mở trình duyệt và đăng nhập vào Teleport Web UI
2. Trong phần **Resources**, tìm server `adt-ml-dify-49-202`
3. Click vào nút **"Connect"** (có dropdown arrow)
4. Chọn **"Web Terminal"** hoặc **"Terminal"**

### Bước 2: Mở Web Terminal

- Web Terminal sẽ mở trong trình duyệt
- Bạn sẽ thấy prompt: `user@adt-ml-dify-49-202:~$`

### Bước 3: Kiểm tra Prerequisites

Chạy các lệnh sau để kiểm tra:

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

**Nếu thiếu tool nào**, cài đặt:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y docker.io docker-compose git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Logout và login lại Teleport Web Terminal để áp dụng group changes
```

### Bước 4: Chuẩn bị thư mục làm việc

```bash
# Di chuyển đến thư mục /opt
cd /opt

# Tạo thư mục và cấp quyền
sudo mkdir -p mlflow-gateway
sudo chown $USER:$USER mlflow-gateway
cd mlflow-gateway
```

### Bước 5: Clone Repository

**Thay `<your-repo-url>` bằng URL Git repository thực tế của bạn:**

```bash
# Clone repository
git clone <your-repo-url> .

# Ví dụ:
# git clone https://github.com/username/mlflow-gateway.git .
# hoặc
# git clone git@github.com:username/mlflow-gateway.git .
```

**Nếu repository có thư mục con:**

```bash
git clone <your-repo-url> temp
mv temp/mlflow-gateway/* .
rm -rf temp
```

### Bước 6: Chạy Script Deploy

Có 2 cách:

#### Cách A: Script Interactive (Khuyến nghị cho lần đầu)

```bash
# Cấp quyền thực thi
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

#### Cách B: Script Đơn Giản (Nếu đã có .env)

```bash
# Tạo file .env từ template
cp env.template .env

# Chỉnh sửa .env và thêm API key
nano .env
# Hoặc
vi .env

# Thêm dòng: OPENAI_API_KEY=sk-your-actual-key-here
# Lưu và thoát (Ctrl+X, Y, Enter cho nano hoặc :wq cho vi)

# Cấp quyền và chạy deploy
chmod +x deploy_web.sh
./deploy_web.sh
```

### Bước 7: Kiểm tra Deployment

```bash
# Kiểm tra container status
docker ps --filter "name=mlflow-gateway"

# Kiểm tra health endpoint
curl http://localhost:5000/health

# Xem logs
docker compose logs -f mlflow-gateway
# Nhấn Ctrl+C để thoát
```

### Bước 8: Test API Endpoint

```bash
# Test chat endpoint
curl -X POST http://localhost:5000/gateway/chat/invocations \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello"}]}'
```

**Kết quả mong đợi**: JSON response từ OpenAI API

---

## 🎯 Phương Pháp 2: Deploy Qua Teleport CLI (Từ máy local)

### Bước 1: Cài đặt Teleport Client

**Windows:**
```powershell
# Với Chocolatey
choco install teleport

# Hoặc download từ: https://goteleport.com/docs/installation/
```

**Linux/macOS:**
```bash
curl https://goteleport.com/static/install.sh | bash -s 13.4.15
```

### Bước 2: Đăng nhập Teleport

```bash
tsh login --proxy=<teleport-proxy-address>
```

### Bước 3: Chạy Script Deploy

**Windows PowerShell:**
```powershell
cd "C:\Data_Mining\AI Gateway\mlflow-gateway"
.\deploy_to_server.ps1
```

**Linux/macOS Bash:**
```bash
cd /path/to/mlflow-gateway
chmod +x teleport_deploy.sh
./teleport_deploy.sh [username]
```

Script sẽ tự động:
- Kiểm tra kết nối
- Upload files lên server
- Tạo file .env
- Deploy và verify

---

## ✅ Kiểm Tra Sau Deploy

### Checklist

- [ ] Container đang chạy: `docker ps | grep mlflow-gateway`
- [ ] Health check pass: `curl http://localhost:5000/health`
- [ ] API endpoint trả về response
- [ ] Logs không có errors: `docker compose logs mlflow-gateway`

### Service URLs

- **Local (trên server)**: `http://localhost:5000`
- **Từ network**: `http://10.3.49.202:5000` (nếu firewall cho phép)
- **Health**: `http://10.3.49.202:5000/health`
- **API**: `http://10.3.49.202:5000/gateway/chat/invocations`

---

## 🔧 Quản Lý Service

### Xem logs
```bash
docker compose logs -f mlflow-gateway
```

### Dừng service
```bash
docker compose down
```

### Khởi động lại
```bash
docker compose restart
# hoặc
docker compose down && docker compose up -d
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

---

## 🐛 Troubleshooting

### Lỗi: "Permission denied" khi chạy Docker

```bash
sudo usermod -aG docker $USER
# Logout và login lại Teleport Web Terminal
# Hoặc
newgrp docker
```

### Lỗi: "Cannot connect to Docker daemon"

```bash
sudo systemctl status docker
sudo systemctl start docker
```

### Lỗi: "Port 5000 already in use"

```bash
# Kiểm tra process
sudo lsof -i :5000

# Dừng container cũ
docker compose down
```

### Lỗi: "API key invalid"

```bash
# Kiểm tra file .env
cat .env

# Đảm bảo format đúng: OPENAI_API_KEY=sk-...
# Không có khoảng trắng thừa
```

### Container không start

```bash
# Xem logs chi tiết
docker compose logs mlflow-gateway

# Rebuild từ đầu
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Health check fails

```bash
# Đợi thêm (container cần 30-40 giây)
sleep 30
curl http://localhost:5000/health

# Xem logs
docker compose logs mlflow-gateway | tail -50
```

---

## 📚 Tài Liệu Tham Khảo

- [DEPLOY_WEB_UI.md](DEPLOY_WEB_UI.md) - Hướng dẫn chi tiết Web UI
- [DEPLOY_STEPS.md](DEPLOY_STEPS.md) - Hướng dẫn CLI deployment
- [QUICK_DEPLOY.md](QUICK_DEPLOY.md) - Quick reference
- [TELEPORT_SETUP.md](TELEPORT_SETUP.md) - Setup Teleport client
- [README.md](README.md) - Tổng quan project

---

## 💡 Tips

1. **Lần đầu deploy**: Sử dụng `setup_and_deploy.sh` để được hướng dẫn từng bước
2. **Deploy lại**: Chỉ cần `git pull` và `docker compose up -d --build`
3. **Kiểm tra nhanh**: `curl http://localhost:5000/health`
4. **Xem logs real-time**: `docker compose logs -f mlflow-gateway`
5. **Backup .env**: Giữ file .env an toàn, không commit vào Git

---

## 🎉 Hoàn Thành!

Sau khi deploy thành công, bạn có thể:
- Test API endpoint từ bất kỳ đâu trong network
- Xem logs và monitor service
- Update và redeploy khi cần

Chúc bạn deploy thành công! 🚀

