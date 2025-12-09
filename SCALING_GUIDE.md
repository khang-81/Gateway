# Hướng Dẫn Scaling MLflow Gateway

## Vấn Đề

Khi scale với `docker compose up -d --scale mlflow-gateway=3`, tất cả containers cố gắng bind vào cùng port 5000, gây lỗi:
```
Bind for 0.0.0.0:5000 failed: port is already allocated
```

## Giải Pháp

### Cách 1: Sử dụng Nginx Load Balancer (Khuyến nghị cho Production)

**Ưu điểm:**
- Single entry point (port 5000)
- Load balancing tự động
- Health checks
- Dễ quản lý

**Cách sử dụng:**

```bash
# 1. Đảm bảo nginx.conf đã có
ls nginx.conf

# 2. Scale với docker-compose.prod.yml (đã có nginx)
docker compose -f docker-compose.prod.yml up -d --scale mlflow-gateway=3

# 3. Kiểm tra
docker ps --filter "name=mlflow-gateway"
docker ps --filter "name=nginx"

# 4. Test qua nginx
curl http://localhost:5000/health
```

**Cấu trúc:**
```
Client → Nginx (port 5000) → Gateway instances (internal)
```

### Cách 2: Scale với Port Range (Đơn giản, không cần nginx)

**Ưu điểm:**
- Đơn giản, không cần nginx
- Mỗi instance có port riêng

**Nhược điểm:**
- Phải biết port của từng instance
- Không có load balancing tự động

**Cách sử dụng:**

```bash
# 1. Scale với docker-compose.scale.yml
docker compose -f docker-compose.scale.yml up -d --scale mlflow-gateway=3

# 2. Kiểm tra ports
docker ps --filter "name=mlflow-gateway" --format "{{.Names}}\t{{.Ports}}"

# 3. Test từng instance
curl http://localhost:5000/health  # Instance 1
curl http://localhost:5001/health  # Instance 2
curl http://localhost:5002/health  # Instance 3
```

### Cách 3: Single Instance (Development)

**Khi không cần scale:**

```bash
# Sử dụng docker-compose.yml (single instance)
docker compose up -d

# Hoặc docker-compose.prod.yml với scale=1
docker compose -f docker-compose.prod.yml up -d --scale mlflow-gateway=1
```

## So Sánh

| Method | Ports | Load Balancing | Complexity |
|--------|-------|----------------|------------|
| Nginx LB | Single (5000) | ✅ Có | Medium |
| Port Range | Multiple (5000-5002) | ❌ Không | Low |
| Single Instance | Single (5000) | ❌ Không | Low |

## Kiểm Tra Scaling

```bash
# Check số lượng instances
docker ps --filter "name=mlflow-gateway" | wc -l

# Check status
docker ps --filter "name=mlflow-gateway"

# Check nginx (nếu dùng)
docker ps --filter "name=nginx"

# Test load balancing (nếu dùng nginx)
for i in {1..10}; do
  curl -s http://localhost:5000/health | jq -r '.status'
done
```

## Troubleshooting

### Lỗi: Port already allocated

**Giải pháp:**
- Dùng nginx load balancer (Cách 1)
- Hoặc dùng port range (Cách 2)
- Hoặc stop containers cũ trước: `docker compose down`

### Nginx không start

**Giải pháp:**
```bash
# Check nginx logs
docker logs mlflow-gateway-nginx

# Verify nginx.conf
cat nginx.conf

# Restart nginx
docker restart mlflow-gateway-nginx
```

### Instances không healthy

**Giải pháp:**
```bash
# Check logs của từng instance
docker compose logs mlflow-gateway

# Check health của từng instance
docker exec gateway-mlflow-gateway-1 curl http://localhost:5000/health
docker exec gateway-mlflow-gateway-2 curl http://localhost:5000/health
```

## Best Practices

1. **Production**: Dùng nginx load balancer (Cách 1)
2. **Development**: Single instance (docker-compose.yml)
3. **Testing**: Port range (Cách 2) để test từng instance riêng
4. **Monitor**: Check health của tất cả instances
5. **Logs**: Centralized logging cho tất cả instances

