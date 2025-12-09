#!/usr/bin/env python3
"""
MLflow Gateway API Test Script
Test và đánh giá API Gateway
"""

import requests
import json
import sys
import time
from datetime import datetime
from typing import Dict, Any

# Configuration
GATEWAY_URL = "http://localhost:5000"
ENDPOINT = "/gateway/chat/invocations"
TIMEOUT = 30

def test_health():
    """Test health endpoint"""
    print("=" * 60)
    print("Testing Health Endpoint")
    print("=" * 60)
    try:
        response = requests.get(f"{GATEWAY_URL}/health", timeout=5)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_chat_request(messages: list, temperature: float = 0.7, max_tokens: int = 100):
    """Test chat endpoint với messages"""
    url = f"{GATEWAY_URL}{ENDPOINT}"
    headers = {"Content-Type": "application/json"}
    
    payload = {
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens
    }
    
    print(f"\nRequest URL: {url}")
    print(f"Request Payload: {json.dumps(payload, indent=2, ensure_ascii=False)}")
    
    start_time = time.time()
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=TIMEOUT)
        elapsed_time = time.time() - start_time
        
        print(f"\nResponse Status: {response.status_code}")
        print(f"Response Time: {elapsed_time:.2f}s")
        
        if response.status_code == 200:
            result = response.json()
            print(f"Response: {json.dumps(result, indent=2, ensure_ascii=False)}")
            
            # Extract token usage if available
            if "usage" in result:
                usage = result["usage"]
                print(f"\nToken Usage:")
                print(f"  Prompt tokens: {usage.get('prompt_tokens', 'N/A')}")
                print(f"  Completion tokens: {usage.get('completion_tokens', 'N/A')}")
                print(f"  Total tokens: {usage.get('total_tokens', 'N/A')}")
            
            return True, result
        else:
            print(f"Error Response: {response.text}")
            return False, None
            
    except requests.exceptions.Timeout:
        print(f"Error: Request timeout after {TIMEOUT}s")
        return False, None
    except Exception as e:
        print(f"Error: {e}")
        return False, None

def calculate_cost(usage: Dict[str, Any], model: str = "gpt-3.5-turbo"):
    """Tính toán chi phí dựa trên token usage"""
    # Pricing per 1K tokens (as of 2024)
    pricing = {
        "gpt-3.5-turbo": {
            "input": 0.0005,   # $0.50 per 1M tokens
            "output": 0.0015   # $1.50 per 1M tokens
        },
        "gpt-4": {
            "input": 0.03,     # $30 per 1M tokens
            "output": 0.06     # $60 per 1M tokens
        },
        "gpt-4-turbo": {
            "input": 0.01,     # $10 per 1M tokens
            "output": 0.03     # $30 per 1M tokens
        }
    }
    
    if model not in pricing:
        model = "gpt-3.5-turbo"
    
    prompt_tokens = usage.get("prompt_tokens", 0)
    completion_tokens = usage.get("completion_tokens", 0)
    
    input_cost = (prompt_tokens / 1000) * pricing[model]["input"]
    output_cost = (completion_tokens / 1000) * pricing[model]["output"]
    total_cost = input_cost + output_cost
    
    return {
        "input_cost": input_cost,
        "output_cost": output_cost,
        "total_cost": total_cost,
        "prompt_tokens": prompt_tokens,
        "completion_tokens": completion_tokens
    }

def run_test_suite():
    """Chạy bộ test đầy đủ"""
    print("=" * 60)
    print("MLflow Gateway API Test Suite")
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    # Test 1: Health check
    if not test_health():
        print("\nHealth check failed. Gateway may not be running.")
        sys.exit(1)
    
    # Test 2: Simple chat
    print("\n" + "=" * 60)
    print("Test 1: Simple Chat Request")
    print("=" * 60)
    success, result = test_chat_request([
        {"role": "user", "content": "Hello, how are you?"}
    ])
    
    if success and result and "usage" in result:
        cost = calculate_cost(result["usage"])
        print(f"\nCost Analysis:")
        print(f"  Input tokens: {cost['prompt_tokens']}")
        print(f"  Output tokens: {cost['completion_tokens']}")
        print(f"  Estimated cost: ${cost['total_cost']:.6f}")
    
    # Test 3: Multi-turn conversation
    print("\n" + "=" * 60)
    print("Test 2: Multi-turn Conversation")
    print("=" * 60)
    test_chat_request([
        {"role": "user", "content": "What is machine learning?"},
        {"role": "assistant", "content": "Machine learning is a subset of artificial intelligence."},
        {"role": "user", "content": "Can you give me a simple example?"}
    ])
    
    # Test 4: Complex request
    print("\n" + "=" * 60)
    print("Test 3: Complex Request with Parameters")
    print("=" * 60)
    success, result = test_chat_request([
        {"role": "user", "content": "Explain quantum computing in simple terms, limit to 50 words."}
    ], temperature=0.5, max_tokens=100)
    
    if success and result and "usage" in result:
        cost = calculate_cost(result["usage"])
        print(f"\nCost Analysis:")
        print(f"  Input tokens: {cost['prompt_tokens']}")
        print(f"  Output tokens: {cost['completion_tokens']}")
        print(f"  Estimated cost: ${cost['total_cost']:.6f}")
    
    print("\n" + "=" * 60)
    print("Test Suite Completed")
    print("=" * 60)

if __name__ == "__main__":
    run_test_suite()

