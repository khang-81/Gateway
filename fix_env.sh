#!/bin/bash
# Script to fix .env file issue
# Run this in the deployment directory

set -e

echo "=========================================="
echo "Fixing .env file for MLflow Gateway"
echo "=========================================="
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "ERROR: .env file not found!"
    echo ""
    echo "Creating .env file from template..."
    
    if [ -f "env.template" ]; then
        cp env.template .env
        echo "✓ Created .env from env.template"
    else
        echo "Creating basic .env file..."
        cat > .env << EOF
OPENAI_API_KEY=your_openai_api_key_here
EOF
        echo "✓ Created basic .env file"
    fi
    
    echo ""
    echo "⚠️  Please edit .env file and add your OpenAI API Key:"
    echo "   nano .env"
    echo "   # Change: OPENAI_API_KEY=your_openai_api_key_here"
    echo "   # To: OPENAI_API_KEY=sk-your-actual-key"
    echo ""
    read -p "Press Enter after you've updated .env file..."
fi

# Check .env content
echo "Checking .env file..."
if ! grep -q "^OPENAI_API_KEY=" .env; then
    echo "ERROR: OPENAI_API_KEY not found in .env file"
    echo ""
    echo "Current .env content:"
    cat .env
    echo ""
    echo "Please add: OPENAI_API_KEY=sk-your-actual-key"
    exit 1
fi

# Check if API key is placeholder
if grep -q "OPENAI_API_KEY=your_openai_api_key_here" .env || grep -q "OPENAI_API_KEY=$" .env; then
    echo "⚠️  WARNING: OPENAI_API_KEY appears to be a placeholder"
    echo ""
    echo "Please update .env file with your actual API key:"
    echo "   nano .env"
    echo ""
    read -p "Press Enter after you've updated .env file..."
fi

# Validate .env format
echo "Validating .env file format..."
while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue
    
    # Check for spaces around =
    if [[ "$key" =~ [[:space:]] ]] || [[ "$value" =~ ^[[:space:]] ]]; then
        echo "⚠️  WARNING: Spaces detected in .env file"
        echo "   Line: $key=$value"
    fi
done < .env

# Show masked .env content
echo ""
echo "Current .env content (masked):"
sed 's/OPENAI_API_KEY=.*/OPENAI_API_KEY=***HIDDEN***/' .env

# Set proper permissions
chmod 600 .env
echo "✓ Set .env permissions to 600"

echo ""
echo "=========================================="
echo "✓ .env file check complete"
echo "=========================================="
echo ""
echo "Now restart the container:"
echo "   docker compose down"
echo "   docker compose up -d"
echo ""

