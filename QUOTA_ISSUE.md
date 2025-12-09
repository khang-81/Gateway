# OpenAI API Quota Issue - Hướng Dẫn

## Vấn Đề

Khi chạy evaluation, bạn có thể gặp lỗi:
```
You exceeded your current quota, please check your plan and billing details.
```

**Điều quan trọng:** Gateway đang hoạt động đúng! Vấn đề là với OpenAI API quota, không phải với gateway.

## Giải Pháp

### 1. Kiểm Tra Billing

Truy cập: https://platform.openai.com/account/billing

Kiểm tra:
- Usage hiện tại
- Quota limit
- Payment method đã được thêm chưa
- Billing cycle

### 2. Thêm Payment Method

Nếu chưa có payment method:
1. Vào https://platform.openai.com/account/billing
2. Click "Add payment method"
3. Thêm credit card hoặc payment method khác
4. Đợi vài phút để hệ thống cập nhật

### 3. Đợi Quota Reset

Quota thường reset theo:
- Monthly cycle (nếu có payment method)
- Hoặc theo plan của bạn

Kiểm tra billing page để xem khi nào quota reset.

### 4. Sử Dụng API Key Khác

Nếu có nhiều API keys:
1. Tạo API key mới: https://platform.openai.com/account/api-keys
2. Update trong `.env` file:
   ```bash
   nano .env
   # Thay OPENAI_API_KEY=sk-new-key-here
   ```
3. Restart container:
   ```bash
   ./fix_env_and_restart.sh
   ```

### 5. Kiểm Tra Usage

Xem usage hiện tại:
- https://platform.openai.com/usage
- Xem số tokens đã sử dụng
- Xem costs đã tích lũy

## Verify Gateway Vẫn Hoạt Động

Gateway vẫn hoạt động đúng. Verify:

```bash
# Health check vẫn OK
curl http://localhost:5000/health
# Response: {"status":"OK"}

# Container vẫn running
docker ps --filter "name=mlflow-gateway"
# Status: Up (healthy)
```

## Khi Quota Đã Được Fix

Sau khi fix quota issue:

```bash
# Test lại
python3 evaluate_gateway.py

# Hoặc
./evaluate.sh
```

## Common Quota Limits

- **Free tier**: $5 credit (thường hết nhanh)
- **Pay-as-you-go**: Dựa trên usage, cần payment method
- **Team/Enterprise**: Higher limits

Kiểm tra plan của bạn tại: https://platform.openai.com/account/billing

## Tips

1. **Monitor usage**: Check usage thường xuyên để tránh hết quota đột ngột
2. **Set up billing alerts**: Nhận email khi gần hết quota
3. **Use cost tracking**: Sử dụng `analyze_costs.py` để track costs
4. **Optimize requests**: Giảm max_tokens nếu không cần thiết

## Verify Gateway Không Cần API Quota

Bạn có thể verify gateway hoạt động đúng mà không cần OpenAI API quota:

### Python Script

```bash
python3 verify_gateway.py
```

Script này sẽ:
- ✓ Check health endpoint
- ✓ Verify endpoints exist
- ✓ Check configuration
- ✓ Verify container status
- ✓ Check logs

### Bash Script

```bash
chmod +x verify_gateway.sh
./verify_gateway.sh
```

### Manual Verification

```bash
# 1. Health check
curl http://localhost:5000/health
# Response: {"status":"OK"}

# 2. Container status
docker ps --filter "name=mlflow-gateway"
# Status: Up (healthy)

# 3. Endpoint exists (will return error but that's OK)
curl -X POST http://localhost:5000/gateway/chat/invocations \
  -H "Content-Type: application/json" \
  -d '{"messages":[]}'
# Status 400/401/429 = Endpoint exists and working

# 4. Check logs
docker logs mlflow-gateway | grep -i "startup complete"
# Should show: Application startup complete
```

## Summary

- ✅ Gateway hoạt động đúng
- ❌ OpenAI API quota đã hết
- ✅ Fix bằng cách: Add payment method, đợi reset, hoặc dùng key khác
- ✅ Verify gateway structure: `python3 verify_gateway.py`

