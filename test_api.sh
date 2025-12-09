#!/bin/bash
# MLflow Gateway API Test Script
# Test và đánh giá API Gateway

set -e

GATEWAY_URL="http://localhost:5000"
ENDPOINT="/gateway/chat/invocations"

echo "============================================================"
echo "MLflow Gateway API Test Suite"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"

# Test 1: Health check
echo ""
echo "============================================================"
echo "Test 1: Health Check"
echo "============================================================"
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "${GATEWAY_URL}/health" || echo "000")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
BODY=$(echo "$HEALTH_RESPONSE" | sed '$d')

echo "Status Code: $HTTP_CODE"
echo "Response: $BODY"

if [ "$HTTP_CODE" != "200" ]; then
    echo "Health check failed. Gateway may not be running."
    exit 1
fi

# Test 2: Simple chat request
echo ""
echo "============================================================"
echo "Test 2: Simple Chat Request"
echo "============================================================"

REQUEST_BODY='{
  "messages": [
    {
      "role": "user",
      "content": "Hello, how are you?"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 100
}'

echo "Request:"
echo "$REQUEST_BODY" | jq '.'

echo ""
echo "Sending request..."
START_TIME=$(date +%s.%N)
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY" \
  "${GATEWAY_URL}${ENDPOINT}" || echo "000")
END_TIME=$(date +%s.%N)
ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "Response Status: $HTTP_CODE"
echo "Response Time: ${ELAPSED}s"
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"

# Extract token usage if available
if echo "$BODY" | jq -e '.usage' > /dev/null 2>&1; then
    echo ""
    echo "Token Usage:"
    echo "$BODY" | jq '.usage'
fi

# Test 3: Multi-turn conversation
echo ""
echo "============================================================"
echo "Test 3: Multi-turn Conversation"
echo "============================================================"

REQUEST_BODY='{
  "messages": [
    {
      "role": "user",
      "content": "What is machine learning?"
    },
    {
      "role": "assistant",
      "content": "Machine learning is a subset of artificial intelligence."
    },
    {
      "role": "user",
      "content": "Can you give me a simple example?"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 150
}'

echo "Request:"
echo "$REQUEST_BODY" | jq '.'

echo ""
echo "Sending request..."
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY" \
  "${GATEWAY_URL}${ENDPOINT}")

echo "Response:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"

echo ""
echo "============================================================"
echo "Test Suite Completed"
echo "============================================================"

