# Hướng Dẫn Deploy Hoàn Chỉnh - MLflow Gateway

## Bước 1: Kiểm Tra Trạng Thái

Container đã chạy thành công! Kiểm tra lại:

```bash
# Kiểm tra container status
docker ps --filter "name=mlflow-gateway"

# Kiểm tra health
curl http://localhost:5000/health

# Kiểm tra logs
docker compose logs --tail=20 mlflow-gateway
```

**Kết quả mong đợi:**
- Container status: `Up` và `healthy`
- Health endpoint: `{"status":"OK"}`
- Logs không có errors

## Bước 2: Đánh Giá Gateway

### Chạy Evaluation

```bash
# Cấp quyền cho scripts
chmod +x *.sh

# Chạy evaluation
./evaluate.sh
```

Hoặc chạy trực tiếp:

```bash
python3 evaluate_gateway.py
```

**Kết quả mong đợi:**
- Health check passed
- Test requests thành công
- Token usage được hiển thị
- Cost được tính toán

### Test Thủ Công

```bash
# Simple test
curl -X POST http://localhost:5000/gateway/chat/invocations \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello"}]}'
```

## Bước 3: Phân Tích Chi Phí

Sau khi có requests thành công, phân tích costs:

```bash
# Analyze costs từ Docker logs
python3 analyze_costs.py --container mlflow-gateway

# Với model cụ thể
python3 analyze_costs.py --container mlflow-gateway --model gpt-4
```

**Output bao gồm:**
- Tổng số requests
- Tổng tokens
- Tổng chi phí
- Chi phí trung bình mỗi request

## Bước 4: Kiểm Tra Logs

```bash
# Real-time logs
docker compose logs -f mlflow-gateway

# Last 50 lines
docker compose logs --tail=50 mlflow-gateway

# Export logs
docker compose logs mlflow-gateway > gateway.log
```

## Bước 5: Quản Lý Service

### Xem Status

```bash
# Quick check
./check_gateway.sh

# Container status
docker ps --filter "name=mlflow-gateway"

# Health check
curl http://localhost:5000/health
```

### Restart Service

```bash
# Restart
docker compose restart

# Hoặc stop và start lại
docker compose down
docker compose up -d
```

### Update Service

```bash
# Pull code mới
git pull

# Rebuild và restart
docker compose down
docker compose build
docker compose up -d
```

## Bước 6: Scale Service (Production)

```bash
# Scale với docker-compose.prod.yml
docker compose -f docker-compose.prod.yml up -d --scale mlflow-gateway=3

# Kiểm tra
docker ps --filter "name=mlflow-gateway"
```

## Troubleshooting

### OpenAI API Quota Exceeded

**Triệu chứng:** `You exceeded your current quota, please check your plan and billing details`

**Giải pháp:**
1. Kiểm tra billing: https://platform.openai.com/account/billing
2. Thêm payment method nếu cần
3. Đợi quota reset (thường là monthly)
4. Sử dụng API key khác có quota còn lại

**Lưu ý:** Gateway đang hoạt động đúng. Vấn đề là với OpenAI API quota, không phải gateway.

### Nếu Container Restarting

```bash
# Check logs
docker compose logs mlflow-gateway | tail -50

# Fix environment variable
./fix_env_and_restart.sh
```

### Nếu Health Check Failed

```bash
# Đợi thêm thời gian (container cần 30-60 giây)
sleep 60
curl http://localhost:5000/health

# Check container logs
docker compose logs mlflow-gateway
```

### Nếu API Key Invalid

```bash
# Check API key
./check_api_key.sh

# Fix và restart
./fix_env_and_restart.sh
```

### Nếu Rate Limit Exceeded

```bash
# Đợi vài phút rồi thử lại
# Hoặc sử dụng API key khác
```

## Service URLs

- **Local**: `http://localhost:5000`
- **Network**: `http://10.3.49.202:5000`
- **Health**: `http://10.3.49.202:5000/health`
- **API**: `http://10.3.49.202:5000/gateway/chat/invocations`

## Quick Commands Reference

```bash
# Status check
./check_gateway.sh

# Evaluate gateway
./evaluate.sh

# Analyze costs
python3 analyze_costs.py --container mlflow-gateway

# View logs
docker compose logs -f mlflow-gateway

# Restart
docker compose restart

# Stop
docker compose down

# Start
docker compose up -d
```

## Next Steps

1. ✅ Container đã chạy và healthy
2. ✅ Test gateway với evaluation script
3. ✅ Monitor costs với analyze script
4. ✅ Scale service nếu cần (production)
5. ✅ Setup monitoring và alerting (optional)

## Success Checklist

- [x] Container running và healthy
- [ ] Evaluation script chạy thành công
- [ ] API requests trả về responses hợp lệ
- [ ] Cost tracking hoạt động
- [ ] Logs được ghi lại đúng
- [ ] Service có thể scale (nếu cần)

