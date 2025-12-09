#!/bin/bash
# MLflow Gateway Health Check Script (Bash)
# Tests the chat endpoint and validates response

URL="http://localhost:5000/gateway/chat/invocations"
BODY='{"messages":[{"role":"user","content":"health check"}]}'

echo "Sending health check request to $URL..."

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$URL" \
    -H "Content-Type: application/json" \
    -d "$BODY")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY_CONTENT=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ne 200 ]; then
    echo "Health check FAILED: HTTP $HTTP_CODE" >&2
    echo "Response: $BODY_CONTENT" >&2
    exit 1
fi

# Check if response contains choices, output, or candidates field
if echo "$BODY_CONTENT" | grep -qE '"choices"|"output"|"candidates"'; then
    echo "Health check PASSED"
    echo "Response:"
    echo "$BODY_CONTENT" | jq '.' 2>/dev/null || echo "$BODY_CONTENT"
    exit 0
else
    echo "Health check FAILED: Response missing expected fields" >&2
    echo "Response: $BODY_CONTENT" >&2
    exit 1
fi

