# 🔧 Quick Fix - Environment Variable Issue

## Vấn Đề

Container restart liên tục với lỗi:
```
Error: Invalid value for '--config-path': Invalid gateway configuration: Environment variable '{OPENAI_API_KEY}' is not set
```

## ✅ Giải Pháp Nhanh

### Bước 1: Dừng container

```bash
docker compose down
```

### Bước 2: Kiểm tra và sửa file .env

```bash
# Kiểm tra file .env có tồn tại
ls -la .env

# Xem nội dung (ẩn API key)
cat .env | sed 's/OPENAI_API_KEY=.*/OPENAI_API_KEY=***HIDDEN***/'
```

**Nếu file .env không tồn tại hoặc sai:**

```bash
# Tạo file .env từ template
cp env.template .env

# Hoặc tạo thủ công
cat > .env << EOF
OPENAI_API_KEY=sk-your-actual-openai-api-key-here
EOF

# Chỉnh sửa với editor
nano .env
# Hoặc
vi .env
```

**Đảm bảo format đúng:**
- ✅ `OPENAI_API_KEY=sk-...` (không có khoảng trắng)
- ❌ `OPENAI_API_KEY = sk-...` (có khoảng trắng - SAI)
- ❌ `OPENAI_API_KEY=sk-... ` (có khoảng trắng cuối - SAI)

### Bước 3: Set permissions

```bash
chmod 600 .env
```

### Bước 4: Verify .env file

```bash
# Kiểm tra API key có được set
grep OPENAI_API_KEY .env

# Test export (không hiển thị giá trị)
export $(grep -v '^#' .env | xargs)
echo "API Key is set: $([ -n "$OPENAI_API_KEY" ] && echo 'YES' || echo 'NO')"
```

### Bước 5: Restart container

```bash
# Rebuild và start
docker compose down
docker compose up -d

# Đợi 30 giây
sleep 30

# Kiểm tra status
docker compose ps

# Xem logs
docker compose logs mlflow-gateway
```

## 🔍 Kiểm Tra Chi Tiết

### Nếu vẫn lỗi, kiểm tra:

1. **File .env có đúng format không:**
   ```bash
   cat .env
   # Phải thấy: OPENAI_API_KEY=sk-...
   ```

2. **Environment variable có được load không:**
   ```bash
   # Test trong container
   docker compose exec mlflow-gateway env | grep OPENAI
   ```

3. **Config file có đúng không:**
   ```bash
   cat config.yaml
   # Phải thấy: openai_api_key: ${OPENAI_API_KEY}
   ```

## 🚀 Sử Dụng Script Tự Động

Chạy script fix tự động:

```bash
chmod +x fix_env.sh
./fix_env.sh
```

Script sẽ:
- Kiểm tra file .env
- Tạo nếu chưa có
- Validate format
- Hướng dẫn sửa nếu cần

## ✅ Sau Khi Fix

Container sẽ:
- ✅ Start thành công
- ✅ Status: `Up` (không phải `Restarting`)
- ✅ Health check pass sau 30-60 giây

Test:
```bash
# Đợi 60 giây
sleep 60

# Test health
curl http://localhost:5000/health

# Test API
curl -X POST http://localhost:5000/gateway/chat/invocations \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello"}]}'
```

