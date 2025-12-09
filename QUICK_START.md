# 🚀 Quick Start - Deploy MLflow Gateway

Hướng dẫn nhanh để deploy MLflow Gateway lên server 10.3.49.202 qua Teleport Web UI.

## 📋 Chuẩn Bị

- ✅ Truy cập Teleport Web UI
- ✅ Git repository URL
- ✅ OpenAI API Key

## 🎯 Các Bước Deploy

### Bước 1: Truy cập Teleport Web UI

1. Đăng nhập Teleport Web UI
2. Tìm server `adt-ml-dify-49-202` (10.3.49.202)
3. Click **"Connect"** → Chọn **"Web Terminal"**

### Bước 2: Clone Repository

```bash
cd /opt
sudo mkdir -p mlflow-gateway && sudo chown $USER:$USER mlflow-gateway
cd mlflow-gateway

# Clone repository (thay <repo-url> bằng URL thực tế)
git clone <repo-url> .
```

### Bước 3: Chạy Script Deploy

```bash
# Cấp quyền thực thi
chmod +x setup_and_deploy.sh

# Chạy script (sẽ hỏi API key)
./setup_and_deploy.sh
```

Script sẽ:
- ✅ Kiểm tra prerequisites
- ✅ Hỏi OpenAI API Key
- ✅ Tạo file .env
- ✅ Build và start container
- ✅ Verify deployment

### Bước 4: Kiểm Tra

```bash
# Kiểm tra container
docker ps --filter "name=mlflow-gateway"

# Test health
curl http://localhost:5000/health

# Test API
curl -X POST http://localhost:5000/gateway/chat/invocations \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello"}]}'
```

## ✅ Thành Công!

Nếu container status là **"Up"** và health check pass → Deploy thành công! 🎉

## 🔧 Nếu Gặp Lỗi

### Lỗi: "Environment variable not set"

```bash
# Kiểm tra file .env
cat .env

# Export biến và restart
export OPENAI_API_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d'=' -f2)
docker compose down
docker compose build
OPENAI_API_KEY="$OPENAI_API_KEY" docker compose up -d
```

### Xem logs để debug

```bash
docker compose logs mlflow-gateway
```

Xem thêm: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 📚 Tài Liệu Chi Tiết

- [DEPLOY_GUIDE.md](DEPLOY_GUIDE.md) - Hướng dẫn đầy đủ step-by-step
- [DEPLOY_WEB_UI.md](DEPLOY_WEB_UI.md) - Hướng dẫn Web UI deployment
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Troubleshooting guide

