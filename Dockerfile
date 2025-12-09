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

# Copy entrypoint script
COPY entrypoint.sh /opt/mlflow/entrypoint.sh
RUN chmod +x /opt/mlflow/entrypoint.sh

# Expose MLflow Gateway port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Use entrypoint script to ensure environment variables are set
ENTRYPOINT ["/opt/mlflow/entrypoint.sh"]

