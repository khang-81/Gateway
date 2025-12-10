# HƯỚNG DẪN DEPLOY VÀ LẤY KẾT QUẢ THẬT

## 🎯 Mục Tiêu

Hướng dẫn từng bước để deploy MLflow Gateway và lấy kết quả thực tế để báo cáo.

---

## 📋 BƯỚC 1: CHUẨN BỊ

### 1.1. Kiểm tra môi trường

```bash
# Kiểm tra Docker
docker --version
docker compose version

# Kiểm tra Python
python3 --version

# Kiểm tra Git (nếu clone từ repo)
git --version
```

### 1.2. Chuẩn bị API Key

```bash
# Vào thư mục project
cd mlflow-gateway

# Copy template
cp env.template .env

# Mở file .env và thêm API key
nano .env
# Hoặc
vi .env
# Hoặc trên Windows: notepad .env
```

**Nội dung file .env:**
```
OPENAI_API_KEY=sk-your-actual-api-key-here
```

**⚠️ QUAN TRỌNG:**
- API key phải là key thật, không phải placeholder
- Không có quotes, không có spaces
- Format: `OPENAI_API_KEY=sk-...`

### 1.3. Kiểm tra API Key

```bash
# Cấp quyền cho script
chmod +x check_api_key.sh

# Kiểm tra API key
./check_api_key.sh
```

**Expected output:**
```
✓ API key found (length: 51)
✓ API key format is valid
✓ API key is working
```

---

## 🚀 BƯỚC 2: DEPLOY GATEWAY

### 2.1. Deploy Development (Single Instance)

```bash
# Cấp quyền cho scripts
chmod +x *.sh

# Deploy
docker compose up -d
```

**Kiểm tra:**
```bash
# Check container status
docker ps --filter "name=mlflow-gateway"

# Expected output:
# CONTAINER ID   IMAGE                    STATUS
# xxxxx         mlflow-gateway:latest     Up X seconds (healthy)
```

### 2.2. Verify Health

```bash
# Đợi 30-60 giây cho container start
sleep 60

# Health check
curl http://localhost:5000/health

# Expected output:
# {"status":"OK"}
```

### 2.3. Nếu có lỗi - Fix Environment

```bash
# Sử dụng script tự động
./fix_env_and_restart.sh

# Hoặc thủ công:
export OPENAI_API_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d'=' -f2- | xargs)
docker compose down
docker compose build --no-cache
OPENAI_API_KEY="$OPENAI_API_KEY" docker compose up -d
```

---

## 🧪 BƯỚC 3: CHẠY EVALUATION (LẤY KẾT QUẢ THẬT)

### 3.1. Chạy Evaluation Script

```bash
# Chạy evaluation
python3 evaluate_gateway.py
```

**Expected output:**
```
======================================================================
MLflow Gateway Evaluation
Gateway URL: http://localhost:5000
Timestamp: 2025-12-10 XX:XX:XX
======================================================================

✓ Health check passed: {'status': 'OK'}

======================================================================
Test 1: Simple Question
======================================================================
✓ Request successful
Response time: 2.34s

Token Usage:
  Prompt: 15
  Completion: 45
  Total: 60
  Cost: $0.000090

Content: AI stands for Artificial Intelligence...

======================================================================
Test 2: Multi-turn Conversation
======================================================================
✓ Request successful
Response time: 3.12s

Token Usage:
  Prompt: 30
  Completion: 89
  Total: 119
  Cost: $0.000179

Content: Here are some examples of AI...

======================================================================
Evaluation Summary
======================================================================
Total Requests: 2
Successful: 2
Failed: 0
Total Cost: $0.000269
Average Cost per Request: $0.000135

✓ Results saved to gateway_results.json
  You can analyze costs from this file:
  python3 analyze_costs.py --response-file gateway_results.json
```

### 3.2. Kiểm tra Results File

```bash
# Xem results file
cat gateway_results.json

# Hoặc format đẹp hơn
python3 -m json.tool gateway_results.json | head -50
```

**File sẽ chứa:**
- Total requests
- Successful/failed count
- Total cost
- Chi tiết từng request (status, tokens, cost, response)

---

## 💰 BƯỚC 4: PHÂN TÍCH CHI PHÍ

### 4.1. Analyze từ Results File

```bash
# Analyze costs
python3 analyze_costs.py --response-file gateway_results.json
```

**Expected output:**
```
======================================================================
Request Statistics
======================================================================
Total Requests: 2
Successful: 2
Failed: 0

======================================================================
Cost Analysis from Response File
======================================================================
Total Requests: 2
Total Prompt Tokens: 45
Total Completion Tokens: 134
Total Tokens: 179
Total Cost: $0.000269
Average Cost per Request: $0.000135

Per-Request Breakdown
======================================================================

Request 1:
  Tokens: 60 (prompt: 15, completion: 45)
  Cost: $0.000090

Request 2:
  Tokens: 119 (prompt: 30, completion: 89)
  Cost: $0.000179
```

### 4.2. Analyze từ Docker Logs (Optional)

```bash
# Analyze từ container logs
python3 analyze_costs.py --container mlflow-gateway

# Nếu không có data trong logs, script sẽ tự động tìm gateway_results.json
```

---

## 📈 BƯỚC 5: SCALE PRODUCTION (Optional)

### 5.1. Scale với Nginx Load Balancer

```bash
# Scale lên 3 instances
docker compose -f docker-compose.prod.yml up -d --scale mlflow-gateway=3

# Đợi 60-90 giây
sleep 90

# Kiểm tra instances
docker ps --filter "name=gateway-mlflow-gateway"

# Expected: 3 gateway instances + 1 nginx
```

### 5.2. Verify Scaling

```bash
# Check nginx
docker ps --filter "name=nginx"

# Test qua nginx
curl http://localhost:5000/health

# Check logs
docker logs mlflow-gateway-nginx | tail -20
```

### 5.3. Hoặc dùng Script

```bash
# Sử dụng script tự động
chmod +x scale_with_nginx.sh
./scale_with_nginx.sh
```

---

## 📊 BƯỚC 6: LẤY KẾT QUẢ ĐỂ BÁO CÁO

### 6.1. Tạo Report File

```bash
# Tạo file report
cat > REPORT_$(date +%Y%m%d).txt << EOF
MLflow Gateway - Kết Quả Thực Tế
Ngày: $(date '+%Y-%m-%d %H:%M:%S')

1. DEPLOYMENT:
$(docker ps --filter "name=mlflow-gateway" --format "table {{.Names}}\t{{.Status}}")

2. EVALUATION RESULTS:
$(python3 evaluate_gateway.py 2>&1 | tail -20)

3. COST ANALYSIS:
$(python3 analyze_costs.py --response-file gateway_results.json 2>&1)

4. LOGS (last 10 lines):
$(docker compose logs --tail=10 mlflow-gateway)
EOF

# Xem report
cat REPORT_*.txt
```

### 6.2. Export Results

```bash
# Export evaluation results
cp gateway_results.json evaluation_results_$(date +%Y%m%d).json

# Export logs
docker compose logs mlflow-gateway > gateway_logs_$(date +%Y%m%d).log

# Export cost analysis
python3 analyze_costs.py --response-file gateway_results.json > cost_analysis_$(date +%Y%m%d).txt
```

### 6.3. Screenshots/Evidence

**Chụp màn hình các lệnh sau:**

1. **Deployment:**
   ```bash
   docker ps --filter "name=mlflow-gateway"
   ```

2. **Health Check:**
   ```bash
   curl http://localhost:5000/health
   ```

3. **Evaluation:**
   ```bash
   python3 evaluate_gateway.py
   ```

4. **Cost Analysis:**
   ```bash
   python3 analyze_costs.py --response-file gateway_results.json
   ```

5. **Scaling (nếu có):**
   ```bash
   docker ps --filter "name=gateway"
   ```

---

## 🔍 TROUBLESHOOTING

### Lỗi: Container restarting

```bash
# Check logs
docker compose logs mlflow-gateway | tail -50

# Fix API key
./fix_env_and_restart.sh
```

### Lỗi: API quota exceeded

```bash
# Kiểm tra API key
./check_api_key.sh

# Nếu quota hết, cần:
# 1. Check billing: https://platform.openai.com/account/billing
# 2. Add payment method
# 3. Hoặc dùng API key khác
```

### Lỗi: No usage data found

```bash
# Đảm bảo đã chạy evaluation
python3 evaluate_gateway.py

# Sau đó analyze
python3 analyze_costs.py --response-file gateway_results.json
```

---

## ✅ CHECKLIST TRƯỚC KHI BÁO CÁO

- [ ] Gateway đã deploy thành công
- [ ] Health check passed
- [ ] Evaluation đã chạy và có kết quả
- [ ] Cost analysis đã có output
- [ ] Results file (`gateway_results.json`) đã được tạo
- [ ] Screenshots/evidence đã chụp
- [ ] Logs đã export (nếu cần)

---

## 📝 TEMPLATE BÁO CÁO

Sử dụng các file sau để báo cáo:
- `BAO_CAO.md` - Báo cáo chi tiết
- `TOM_TAT.md` - Tóm tắt
- `FLOW_DIAGRAMS.md` - Flow diagrams
- `REQUIREMENTS_CHECK.md` - Chi tiết kiểm tra

**Kết quả thực tế:**
- File: `gateway_results.json`
- Cost analysis: Output từ `analyze_costs.py`
- Logs: `docker compose logs mlflow-gateway`

