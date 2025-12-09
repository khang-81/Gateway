FROM python:3.10-slim

WORKDIR /opt/mlflow

# Install system dependencies (curl for healthcheck)
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Install MLflow with gateway support
RUN pip install --no-cache-dir mlflow[gateway]

# Copy configuration file
COPY config.yaml /opt/mlflow/config.yaml

# Expose MLflow Gateway port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Start MLflow Gateway
CMD ["mlflow", "gateway", "start", "--config-path", "/opt/mlflow/config.yaml", "--host", "0.0.0.0", "--port", "5000"]

