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

### 2. Deploy

```bash
docker compose up -d
```

### 3. Kiểm tra

```bash
curl http://localhost:5000/health
```

## Yêu Cầu 1: Deploy và Mở Rộng

### Development (Single Instance)

```bash
docker compose up -d
```

### Production (Scalable)

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

**Cấu hình scaling:**
- Chỉnh sửa `docker-compose.prod.yml`:
  ```yaml
  deploy:
    replicas: 3  # Số instances
  ```

## Yêu Cầu 2: Test và Đánh Giá API Gateway

### Chạy Test Suite

**Python (Khuyến nghị):**
```bash
python3 test_api.py
```

**Bash:**
```bash
chmod +x test_api.sh
./test_api.sh
```

**Test Runner:**
```bash
./run_tests.sh
```

### Test Cases

Test suite bao gồm:
- Health check endpoint
- Simple chat request
- Multi-turn conversation
- Complex requests với parameters
- Token usage extraction
- Cost calculation

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

## Yêu Cầu 3: Logging và Cost Tracking

### Logging Configuration

Gateway đã được cấu hình để log requests và responses:
- Logging driver: json-file
- Max log size: 10MB per file
- Max log files: 3 (dev) / 5 (production)
- Logs chứa token usage information

### Xem Logs

```bash
# Real-time logs
docker compose logs -f mlflow-gateway

# Last 100 lines
docker compose logs --tail=100 mlflow-gateway

# Export logs
docker compose logs mlflow-gateway > gateway.log
```

### Track Costs

**Từ Docker logs:**
```bash
python3 track_costs.py --container mlflow-gateway
```

**Với model cụ thể:**
```bash
python3 track_costs.py --container mlflow-gateway --model gpt-4
```

**Từ log file:**
```bash
python3 track_costs.py --log-file gateway.log
```

**Output bao gồm:**
- Tổng số requests
- Tổng tokens (prompt + completion)
- Tổng chi phí
- Chi phí trung bình mỗi request
- Per-request breakdown (nếu <= 10 requests)

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

### Bước 3: Test

```bash
python3 test_api.py
python3 track_costs.py --container mlflow-gateway
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

### Environment variable not set

```bash
export OPENAI_API_KEY=$(grep "^OPENAI_API_KEY=" .env | cut -d'=' -f2)
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
├── test_api.py              # Python test script
├── test_api.sh              # Bash test script
├── track_costs.py           # Cost tracking script
├── run_tests.sh             # Test runner
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
