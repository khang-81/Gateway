#!/bin/bash
# Check và fix API key trong .env file

set -e

ENV_FILE=".env"

echo "============================================================"
echo "Checking API Key Configuration"
echo "============================================================"

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: .env file not found!"
    echo "Creating .env from template..."
    cp env.template .env
    echo ""
    echo "Please edit .env and add your OpenAI API key:"
    echo "  nano .env"
    echo "  # Add: OPENAI_API_KEY=sk-your-actual-key-here"
    exit 1
fi

# Check API key
API_KEY=$(grep "^OPENAI_API_KEY=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'" | xargs)

if [ -z "$API_KEY" ]; then
    echo "ERROR: OPENAI_API_KEY not found in .env file"
    exit 1
fi

# Check if it's still placeholder
if [[ "$API_KEY" == *"your_openai_api_key_here"* ]] || [[ "$API_KEY" == *"your_key_here"* ]] || [[ "$API_KEY" == *"your_ope"* ]]; then
    echo "ERROR: API key is still placeholder!"
    echo "Current value: ${API_KEY:0:20}..."
    echo ""
    echo "Please update .env file with your actual OpenAI API key:"
    echo "  nano .env"
    echo "  # Change: OPENAI_API_KEY=sk-your-actual-key-here"
    exit 1
fi

# Check format
if [[ ! "$API_KEY" =~ ^sk- ]]; then
    echo "WARNING: API key doesn't start with 'sk-'"
    echo "Current value: ${API_KEY:0:20}..."
    echo "Make sure you're using a valid OpenAI API key"
fi

echo "✓ API key found (length: ${#API_KEY})"
echo "✓ API key format looks valid"

# Test API key
echo ""
echo "Testing API key with OpenAI..."
TEST_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer $API_KEY" \
  https://api.openai.com/v1/models \
  --max-time 10 || echo "000")

HTTP_CODE=$(echo "$TEST_RESPONSE" | tail -n1)
BODY=$(echo "$TEST_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ API key is valid and working"
    exit 0
elif [ "$HTTP_CODE" = "401" ]; then
    echo "✗ API key is invalid (401 Unauthorized)"
    echo "Please check your API key at: https://platform.openai.com/account/api-keys"
    exit 1
elif [ "$HTTP_CODE" = "429" ]; then
    echo "⚠ API key is valid but rate limited (429)"
    echo "This is OK, the key works"
    exit 0
else
    echo "⚠ Could not verify API key (HTTP $HTTP_CODE)"
    echo "The key format looks correct, but verification failed"
    echo "You can still try to use it"
    exit 0
fi








