#!/bin/bash
# Script để lấy kết quả thực tế cho báo cáo

set -e

REPORT_DIR="reports_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

echo "============================================================"
echo "Lấy Kết Quả Thực Tế - MLflow Gateway"
echo "Report Directory: $REPORT_DIR"
echo "============================================================"

# 1. Deployment Status
echo ""
echo "[1/6] Deployment Status..."
docker ps --filter "name=mlflow-gateway" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" > "$REPORT_DIR/01_deployment.txt"
cat "$REPORT_DIR/01_deployment.txt"

# 2. Health Check
echo ""
echo "[2/6] Health Check..."
curl -s http://localhost:5000/health > "$REPORT_DIR/02_health.json" 2>&1 || echo "Health check failed" > "$REPORT_DIR/02_health.json"
cat "$REPORT_DIR/02_health.json"
echo ""

# 3. Run Evaluation
echo ""
echo "[3/6] Running Evaluation..."
if [ -f "evaluate_gateway.py" ]; then
    python3 evaluate_gateway.py > "$REPORT_DIR/03_evaluation.txt" 2>&1 || echo "Evaluation failed" > "$REPORT_DIR/03_evaluation.txt"
    cat "$REPORT_DIR/03_evaluation.txt"
else
    echo "⚠ evaluate_gateway.py not found"
fi

# 4. Cost Analysis
echo ""
echo "[4/6] Cost Analysis..."
if [ -f "gateway_results.json" ]; then
    python3 analyze_costs.py --response-file gateway_results.json > "$REPORT_DIR/04_cost_analysis.txt" 2>&1 || echo "Cost analysis failed" > "$REPORT_DIR/04_cost_analysis.txt"
    cat "$REPORT_DIR/04_cost_analysis.txt"
else
    echo "⚠ gateway_results.json not found. Run evaluation first."
fi

# 5. Container Logs
echo ""
echo "[5/6] Container Logs (last 50 lines)..."
docker compose logs --tail=50 mlflow-gateway > "$REPORT_DIR/05_logs.txt" 2>&1 || echo "Logs not available" > "$REPORT_DIR/05_logs.txt"
echo "Logs saved to $REPORT_DIR/05_logs.txt"

# 6. Scaling Status (if using production)
echo ""
echo "[6/6] Scaling Status..."
if docker ps --filter "name=nginx" --format "{{.Names}}" | grep -q nginx; then
    echo "✓ Nginx load balancer is running"
    docker ps --filter "name=gateway-mlflow-gateway" --format "table {{.Names}}\t{{.Status}}" > "$REPORT_DIR/06_scaling.txt"
    docker ps --filter "name=nginx" --format "table {{.Names}}\t{{.Status}}" >> "$REPORT_DIR/06_scaling.txt"
    cat "$REPORT_DIR/06_scaling.txt"
else
    echo "⚠ Nginx not running (using single instance)"
    echo "Single instance" > "$REPORT_DIR/06_scaling.txt"
fi

# Copy results file if exists
if [ -f "gateway_results.json" ]; then
    cp gateway_results.json "$REPORT_DIR/gateway_results.json"
    echo ""
    echo "✓ Results file copied to $REPORT_DIR/gateway_results.json"
fi

# Create summary
echo ""
echo "============================================================"
echo "Creating Summary Report..."
echo "============================================================"

cat > "$REPORT_DIR/SUMMARY.txt" << EOF
MLflow Gateway - Kết Quả Thực Tế
Ngày: $(date '+%Y-%m-%d %H:%M:%S')
Report Directory: $REPORT_DIR

============================================================
1. DEPLOYMENT STATUS
============================================================
$(cat "$REPORT_DIR/01_deployment.txt")

============================================================
2. HEALTH CHECK
============================================================
$(cat "$REPORT_DIR/02_health.json")

============================================================
3. EVALUATION RESULTS
============================================================
$(tail -30 "$REPORT_DIR/03_evaluation.txt" 2>/dev/null || echo "No evaluation results")

============================================================
4. COST ANALYSIS
============================================================
$(cat "$REPORT_DIR/04_cost_analysis.txt" 2>/dev/null || echo "No cost analysis")

============================================================
5. SCALING STATUS
============================================================
$(cat "$REPORT_DIR/06_scaling.txt")

============================================================
FILES GENERATED:
============================================================
- 01_deployment.txt
- 02_health.json
- 03_evaluation.txt
- 04_cost_analysis.txt
- 05_logs.txt
- 06_scaling.txt
- gateway_results.json (if available)
- SUMMARY.txt (this file)
EOF

cat "$REPORT_DIR/SUMMARY.txt"

echo ""
echo "============================================================"
echo "✓ Hoàn thành!"
echo "============================================================"
echo ""
echo "Tất cả kết quả đã được lưu trong: $REPORT_DIR"
echo ""
echo "Để xem summary:"
echo "  cat $REPORT_DIR/SUMMARY.txt"
echo ""
echo "Để xem từng phần:"
echo "  cat $REPORT_DIR/01_deployment.txt"
echo "  cat $REPORT_DIR/03_evaluation.txt"
echo "  cat $REPORT_DIR/04_cost_analysis.txt"
echo ""

