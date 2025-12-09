# 🔧 Troubleshooting Guide - MLflow Gateway

## 🚨 Lỗi: Environment Variable Not Set

### Triệu chứng
```
Error: Invalid value for '--config-path': Invalid gateway configuration: Environment variable '{OPENAI_API_KEY}' is not set
Container status: Restarting (2)
```

### Giải pháp nhanh

**Bước 1: Kiểm tra file .env**
```bash
cat .env
# Phải chỉ có 1 dòng: OPENAI_API_KEY=sk-...
```

**Bước 2: Export biến môi trường và restart**
```bash
# Export biến từ .env
export OPENAI_API_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d'=' -f2)

# Dừng container
docker compose down

# Rebuild và start với biến môi trường
docker compose build --no-cache
OPENAI_API_KEY="$OPENAI_API_KEY" docker compose up -d

# Đợi 60 giây
sleep 60

# Kiểm tra
docker ps --filter "name=mlflow-gateway"
docker compose logs --tail=30 mlflow-gateway
```

**Bước 3: Hoặc sử dụng script tự động**
```bash
chmod +x fix_and_restart.sh
./fix_and_restart.sh
```

---

## Tình Trạng Deploy Khác

### ✅ Container đang chạy nhưng Health Check Failed

**Triệu chứng:**
- Container `mlflow-gateway` đã start thành công
- Health check endpoint trả về lỗi hoặc timeout

**Nguyên nhân có thể:**
1. Container chưa khởi động hoàn toàn (cần 30-60 giây)
2. MLflow Gateway chưa sẵn sàng nhận requests
3. API key không hợp lệ
4. Config file có lỗi

## 🔍 Các Bước Kiểm Tra

### Bước 1: Xem Logs Chi Tiết

```bash
docker compose logs mlflow-gateway
```

Hoặc xem logs real-time:
```bash
docker compose logs -f mlflow-gateway
```

**Tìm kiếm:**
- Lỗi về API key: `Invalid API key`, `Authentication failed`
- Lỗi về config: `Invalid configuration`, `YAML parsing error`
- Lỗi về network: `Connection refused`, `Timeout`

### Bước 2: Kiểm Tra Container Status

```bash
docker ps --filter "name=mlflow-gateway"
```

Kiểm tra:
- Status phải là `Up` (không phải `Restarting` hoặc `Exited`)
- Uptime phải > 1 phút

### Bước 3: Test Health Endpoint Thủ Công

```bash
# Đợi thêm 30 giây
sleep 30

# Test health endpoint
curl -v http://localhost:5000/health
```

**Kết quả mong đợi:**
- HTTP 200 OK
- JSON response

**Nếu lỗi:**
- `Connection refused`: Container chưa sẵn sàng hoặc port không đúng
- `Timeout`: Container đang khởi động hoặc có vấn đề

### Bước 4: Kiểm Tra File .env

```bash
# Kiểm tra file .env có tồn tại
ls -la .env

# Xem nội dung (ẩn API key)
cat .env | sed 's/OPENAI_API_KEY=.*/OPENAI_API_KEY=***HIDDEN***/'
```

**Đảm bảo:**
- File `.env` tồn tại
- Format đúng: `OPENAI_API_KEY=sk-...`
- Không có khoảng trắng thừa
- API key hợp lệ

### Bước 5: Test API Key Trực Tiếp

```bash
# Test API key với OpenAI
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $(grep OPENAI_API_KEY .env | cut -d'=' -f2)"
```

**Nếu lỗi:**
- `401 Unauthorized`: API key không hợp lệ
- `403 Forbidden`: API key không có quyền
- `429 Too Many Requests`: Quá nhiều requests

### Bước 6: Kiểm Tra Config File

```bash
# Kiểm tra config.yaml
cat config.yaml

# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('config.yaml'))" 2>&1
```

**Đảm bảo:**
- File `config.yaml` đúng format
- Sử dụng `endpoints` (không phải `routes`)
- Sử dụng `endpoint_type` (không phải `route_type`)

## 🛠️ Các Giải Pháp

### Giải Pháp 1: Đợi Thêm Thời Gian

MLflow Gateway cần 30-60 giây để khởi động hoàn toàn:

```bash
# Đợi 60 giây
sleep 60

# Test lại
curl http://localhost:5000/health
```

### Giải Pháp 2: Restart Container

```bash
# Restart container
docker compose restart mlflow-gateway

# Đợi 30 giây
sleep 30

# Test lại
curl http://localhost:5000/health
```

### Giải Pháp 3: Rebuild và Redeploy

```bash
# Dừng container
docker compose down

# Rebuild image
docker compose build --no-cache

# Start lại
docker compose up -d

# Đợi và test
sleep 60
curl http://localhost:5000/health
```

### Giải Pháp 4: Sửa API Key

```bash
# Chỉnh sửa .env
nano .env
# Hoặc
vi .env

# Cập nhật OPENAI_API_KEY=sk-your-actual-key

# Restart container
docker compose restart mlflow-gateway
```

### Giải Pháp 5: Kiểm Tra Logs và Sửa Lỗi

```bash
# Xem logs để tìm lỗi cụ thể
docker compose logs mlflow-gateway | grep -i error
docker compose logs mlflow-gateway | grep -i fail
docker compose logs mlflow-gateway | tail -50
```

Sau đó sửa lỗi tương ứng.

## ✅ Kiểm Tra Deploy Thành Công

### Checklist

- [ ] Container status: `Up` (không phải `Restarting`)
- [ ] Health endpoint: `curl http://localhost:5000/health` trả về 200 OK
- [ ] API endpoint: Test chat endpoint thành công
- [ ] Logs không có errors: `docker compose logs mlflow-gateway | grep -i error`

### Test API Endpoint

```bash
curl -X POST http://localhost:5000/gateway/chat/invocations \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello"}]}'
```

**Kết quả mong đợi:**
- HTTP 200 OK
- JSON response với `choices` hoặc `output` field

## 🚨 Các Lỗi Thường Gặp

### Lỗi: "Invalid API key"

**Nguyên nhân:** API key không hợp lệ hoặc không đúng format

**Giải pháp:**
```bash
# Kiểm tra và sửa .env
cat .env
# Đảm bảo: OPENAI_API_KEY=sk-... (không có khoảng trắng)
```

### Lỗi: "Connection refused" hoặc "Timeout"

**Nguyên nhân:** Container chưa khởi động xong hoặc có vấn đề

**Giải pháp:**
```bash
# Đợi thêm thời gian
sleep 60

# Kiểm tra logs
docker compose logs mlflow-gateway

# Restart nếu cần
docker compose restart mlflow-gateway
```

### Lỗi: "YAML parsing error"

**Nguyên nhân:** File config.yaml có lỗi syntax

**Giải pháp:**
```bash
# Validate YAML
python3 -c "import yaml; yaml.safe_load(open('config.yaml'))"

# Sửa lỗi trong config.yaml
nano config.yaml
```

### Lỗi: "Port 5000 already in use"

**Nguyên nhân:** Port 5000 đã được sử dụng bởi process khác

**Giải pháp:**
```bash
# Tìm process đang dùng port 5000
sudo lsof -i :5000

# Dừng process hoặc đổi port trong docker-compose.yml
```

## 📞 Hỗ Trợ

Nếu vẫn gặp vấn đề:

1. **Xem logs đầy đủ:**
   ```bash
   docker compose logs mlflow-gateway > logs.txt
   cat logs.txt
   ```

2. **Kiểm tra container details:**
   ```bash
   docker inspect mlflow-gateway
   ```

3. **Test network connectivity:**
   ```bash
   docker exec mlflow-gateway curl http://localhost:5000/health
   ```

4. **Kiểm tra environment variables:**
   ```bash
   docker exec mlflow-gateway env | grep OPENAI
   ```

