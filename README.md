# MLflow AI Gateway - Docker Deployment

Môi trường deploy cho MLflow AI Gateway với khả năng mở rộng, testing và cost tracking.

## Yêu Cầu

- Docker và Docker Compose
- Python 3.6+ (cho test scripts)
- OpenAI API Key

## Quick Start

### 1. Chuẩn bị

```bash
cp env.template .env
nano .env  # Thêm: OPENAI_API_KEY=sk-your-actual-key-here
```

**Quan trọng:** Đảm bảo API key là key thực tế, không phải placeholder!

### 2. Kiểm tra API Key

```bash
chmod +x check_api_key.sh
./check_api_key.sh
```

### 3. Deploy

```bash
docker compose up -d
```

### 4. Kiểm tra

```bash
curl http://localhost:5000/health
```

### Fix Issues Tự Động

```bash
chmod +x fix_and_test.sh
./fix_and_test.sh
```

## Yêu Cầu 1: Deploy và Mở Rộng

### Development (Single Instance)

```bash
docker compose up -d
```

### Production (Scalable)

**Lưu ý:** Khi scale, không dùng `container_name` (Docker Compose sẽ tự tạo tên)

```bash
# Scale với docker-compose.prod.yml
docker compose -f docker-compose.prod.yml up -d --scale mlflow-gateway=3
```

**Tính năng:**
- Multiple workers (4 workers) để xử lý concurrent requests
- Resource limits (CPU, Memory)
- Health checks tự động
- Auto-restart on failure
- Logging với rotation

**Fix lỗi scaling:**
Nếu gặp lỗi "container_name must be unique", đảm bảo `container_name` đã được comment trong `docker-compose.prod.yml`

## Yêu Cầu 2: Đánh Giá API Gateway

### Chạy Evaluation

**Python (Khuyến nghị):**
```bash
python3 evaluate_gateway.py
```

**Bash Script:**
```bash
chmod +x evaluate.sh
./evaluate.sh
```

**Với custom URL:**
```bash
GATEWAY_URL=http://10.3.49.202:5000 python3 evaluate_gateway.py
```

**Với test cases từ file:**
```bash
python3 evaluate_gateway.py --test-file test_cases.json --output results.json
```

### Evaluation Features

- Health check tự động
- Gửi requests thực tế đến gateway
- Track token usage từ responses
- Tính toán costs tự động
- Export results ra JSON file
- Support custom test cases

### Test Thủ Công

```bash
# Health check
curl http://localhost:5000/health

# Simple chat
curl -X POST http://localhost:5000/gateway/chat/invocations \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello"}]}'

# Multi-turn conversation
curl -X POST http://localhost:5000/gateway/chat/invocations \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "What is AI?"},
      {"role": "assistant", "content": "AI is artificial intelligence."},
      {"role": "user", "content": "Give me an example."}
    ],
    "temperature": 0.7,
    "max_tokens": 150
  }'
```

## Yêu Cầu 3: Logging và Phân Tích Chi Phí

### Logging Configuration

Gateway đã được cấu hình để log requests và responses:
- Logging driver: json-file
- Max log size: 10MB per file
- Max log files: 3 (dev) / 5 (production)
- Logs chứa token usage information từ responses

### Xem Logs

```bash
# Real-time logs
docker compose logs -f mlflow-gateway

# Last 100 lines
docker compose logs --tail=100 mlflow-gateway

# Export logs
docker compose logs mlflow-gateway > gateway.log
```

### Phân Tích Chi Phí

**Từ Docker logs (Khuyến nghị):**
```bash
python3 analyze_costs.py --container mlflow-gateway
```

**Với model cụ thể:**
```bash
python3 analyze_costs.py --container mlflow-gateway --model gpt-4
```

**Từ response file (JSON):**
```bash
python3 analyze_costs.py --response-file results.json
```

**Output bao gồm:**
- Tổng số requests
- Tổng tokens (prompt + completion)
- Tổng chi phí
- Chi phí trung bình mỗi request
- Per-request breakdown (nếu <= 20 requests)

### Supported Models và Pricing

- `gpt-3.5-turbo` - $0.50/$1.50 per 1M tokens (input/output)
- `gpt-4` - $30/$60 per 1M tokens
- `gpt-4-turbo` - $10/$30 per 1M tokens
- `gpt-4o` - $5/$15 per 1M tokens

## Deploy Qua Teleport Web UI

### Bước 1: Truy cập Teleport Web UI

1. Đăng nhập Teleport Web UI
2. Tìm server `adt-ml-dify-49-202` (10.3.49.202)
3. Click "Connect" → "Web Terminal"

### Bước 2: Clone và Deploy

```bash
cd /opt
sudo mkdir -p mlflow-gateway && sudo chown $USER:$USER mlflow-gateway
cd mlflow-gateway
git clone <your-repo-url> .
cp env.template .env
nano .env  # Thêm API key
chmod +x setup_and_deploy.sh
./setup_and_deploy.sh
```

### Bước 3: Evaluate và Analyze

```bash
python3 evaluate_gateway.py
python3 analyze_costs.py --container mlflow-gateway
```

## Quản Lý Service

```bash
# Xem logs
docker compose logs -f mlflow-gateway

# Dừng
docker compose down

# Khởi động lại
docker compose restart

# Update
git pull
docker compose down
docker compose build
docker compose up -d
```

## Troubleshooting

### API Key Invalid (401 Error)

**Triệu chứng:** `Incorrect API key provided: your_ope************here`

**Giải pháp:**
```bash
# Kiểm tra API key
./check_api_key.sh

# Hoặc kiểm tra thủ công
cat .env | grep OPENAI_API_KEY

# Nếu vẫn là placeholder, cập nhật:
nano .env
# Thay: OPENAI_API_KEY=sk-your-actual-key-here

# Restart container
export OPENAI_API_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d'=' -f2- | xargs)
docker compose down
docker compose build --no-cache
OPENAI_API_KEY="$OPENAI_API_KEY" docker compose up -d
```

### Scaling Error: container_name must be unique

**Triệu chứng:** `can't set container_name and mlflow-gateway as container name must be unique`

**Giải pháp:**
```bash
# Comment out container_name trong docker-compose.prod.yml
# Hoặc sử dụng docker-compose.yml thay vì docker-compose.prod.yml
docker compose up -d --scale mlflow-gateway=3
```

### Test Script: jq command not found

**Giải pháp:**
```bash
# Script đã được fix để không cần jq
# Nếu vẫn lỗi, cài jq hoặc dùng Python script
sudo apt-get install -y jq
# Hoặc
python3 test_api.py
```

### Permission denied cho scripts

```bash
chmod +x *.sh
```

### Environment variable not set

```bash
export OPENAI_API_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d'=' -f2- | xargs)
docker compose down
docker compose build --no-cache
OPENAI_API_KEY="$OPENAI_API_KEY" docker compose up -d
```

### Health check fails

```bash
sleep 60
curl http://localhost:5000/health
docker compose logs mlflow-gateway | tail -50
```

### Port 5000 already in use

```bash
sudo lsof -i :5000
docker compose down
```

### Cost Analysis: No usage data found

**Giải pháp:**
```bash
# Usage data chỉ có khi có requests thực tế
# Chạy evaluation để tạo requests:
python3 evaluate_gateway.py

# Sau đó analyze costs
python3 analyze_costs.py --container mlflow-gateway
```

## Cấu Trúc Project

```
mlflow-gateway/
├── config.yaml              # MLflow Gateway config template
├── Dockerfile               # Container image definition
├── docker-compose.yml       # Development configuration
├── docker-compose.prod.yml  # Production configuration (scalable)
├── env.template             # Environment variables template
├── .env                     # Actual environment variables (gitignored)
├── entrypoint.sh            # Container entrypoint script
├── evaluate_gateway.py      # Python evaluation script (production-ready)
├── analyze_costs.py         # Cost analysis script (production-ready)
├── evaluate.sh               # Evaluation runner script
├── setup_and_deploy.sh      # Interactive deploy script
└── README.md                # This file
```

## Service URLs

- Service: `http://10.3.49.202:5000`
- Health: `http://10.3.49.202:5000/health`
- API: `http://10.3.49.202:5000/gateway/chat/invocations`

## Security

**QUAN TRỌNG:** Không commit API keys vào Git.

- Sử dụng `.env` file (đã gitignore)
- Không hardcode API keys trong code
- Sử dụng secret management tools cho production
