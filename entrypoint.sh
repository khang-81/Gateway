#!/bin/bash
# Entrypoint script to ensure environment variables are available before MLflow starts

set -e

# Check if OPENAI_API_KEY is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "ERROR: OPENAI_API_KEY environment variable is not set"
    echo "Available environment variables:"
    env | sort
    exit 1
fi

echo "✓ OPENAI_API_KEY is set (length: ${#OPENAI_API_KEY})"

# Export to ensure it's available
export OPENAI_API_KEY

# Create dynamic config.yaml with actual API key value
# This ensures MLflow can read the API key directly
cat > /opt/mlflow/config.yaml << EOF
endpoints:
  - name: chat
    endpoint_type: llm/v1/chat
    model:
      provider: openai
      name: gpt-3.5-turbo
      config:
        openai_api_key: ${OPENAI_API_KEY}
        temperature: 0.7
EOF

echo "✓ Created config.yaml with API key"

# Start MLflow Gateway
exec mlflow gateway start \
    --config-path /opt/mlflow/config.yaml \
    --host 0.0.0.0 \
    --port 5000

