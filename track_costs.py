#!/usr/bin/env python3
"""
MLflow Gateway Cost Tracking Script
Theo dõi và tính toán chi phí LLM từ logs
"""

import json
import re
import sys
from datetime import datetime
from typing import Dict, List, Any

# Pricing per 1K tokens (as of 2024)
PRICING = {
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
    },
    "gpt-4o": {
        "input": 0.005,    # $5 per 1M tokens
        "output": 0.015    # $15 per 1M tokens
    }
}

def parse_log_line(line: str) -> Dict[str, Any]:
    """Parse log line để extract request/response info"""
    # Tìm JSON trong log line
    json_match = re.search(r'\{.*\}', line)
    if not json_match:
        return None
    
    try:
        data = json.loads(json_match.group())
        return data
    except:
        return None

def extract_usage_from_logs(log_file: str) -> List[Dict[str, Any]]:
    """Extract token usage từ log file"""
    usages = []
    
    try:
        with open(log_file, 'r', encoding='utf-8') as f:
            for line in f:
                # Tìm usage information trong logs
                if 'usage' in line.lower() or 'token' in line.lower():
                    data = parse_log_line(line)
                    if data and 'usage' in data:
                        usages.append(data['usage'])
    except FileNotFoundError:
        print(f"Log file not found: {log_file}")
        return []
    
    return usages

def calculate_cost_from_usage(usage: Dict[str, Any], model: str = "gpt-3.5-turbo") -> Dict[str, float]:
    """Tính toán chi phí từ usage data"""
    if model not in PRICING:
        model = "gpt-3.5-turbo"
    
    prompt_tokens = usage.get("prompt_tokens", 0)
    completion_tokens = usage.get("completion_tokens", 0)
    total_tokens = usage.get("total_tokens", prompt_tokens + completion_tokens)
    
    input_cost = (prompt_tokens / 1000) * PRICING[model]["input"]
    output_cost = (completion_tokens / 1000) * PRICING[model]["output"]
    total_cost = input_cost + output_cost
    
    return {
        "prompt_tokens": prompt_tokens,
        "completion_tokens": completion_tokens,
        "total_tokens": total_tokens,
        "input_cost": input_cost,
        "output_cost": output_cost,
        "total_cost": total_cost,
        "model": model
    }

def aggregate_costs(usages: List[Dict[str, Any]], model: str = "gpt-3.5-turbo") -> Dict[str, Any]:
    """Tổng hợp chi phí từ nhiều requests"""
    total_prompt_tokens = 0
    total_completion_tokens = 0
    total_cost = 0.0
    request_count = len(usages)
    
    for usage in usages:
        cost_data = calculate_cost_from_usage(usage, model)
        total_prompt_tokens += cost_data["prompt_tokens"]
        total_completion_tokens += cost_data["completion_tokens"]
        total_cost += cost_data["total_cost"]
    
    return {
        "request_count": request_count,
        "total_prompt_tokens": total_prompt_tokens,
        "total_completion_tokens": total_completion_tokens,
        "total_tokens": total_prompt_tokens + total_completion_tokens,
        "total_cost": total_cost,
        "average_cost_per_request": total_cost / request_count if request_count > 0 else 0,
        "model": model
    }

def track_costs_from_docker_logs(container_name: str = "mlflow-gateway", model: str = "gpt-3.5-turbo"):
    """Track costs từ Docker container logs"""
    import subprocess
    
    print("=" * 60)
    print("MLflow Gateway Cost Tracking")
    print(f"Container: {container_name}")
    print(f"Model: {model}")
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    # Get logs từ Docker
    try:
        result = subprocess.run(
            ["docker", "logs", container_name, "--tail", "1000"],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode != 0:
            print(f"Error getting logs: {result.stderr}")
            return
        
        logs = result.stdout
        usages = []
        
        # Parse logs để tìm usage information
        for line in logs.split('\n'):
            if 'usage' in line.lower() or 'token' in line.lower():
                data = parse_log_line(line)
                if data:
                    if 'usage' in data:
                        usages.append(data['usage'])
                    elif 'prompt_tokens' in data or 'completion_tokens' in data:
                        usages.append(data)
        
        if not usages:
            print("\nNo usage data found in logs.")
            print("Note: Enable logging in MLflow Gateway config to track costs.")
            return
        
        # Calculate và display costs
        summary = aggregate_costs(usages, model)
        
        print(f"\nCost Summary:")
        print(f"  Total Requests: {summary['request_count']}")
        print(f"  Total Prompt Tokens: {summary['total_prompt_tokens']:,}")
        print(f"  Total Completion Tokens: {summary['total_completion_tokens']:,}")
        print(f"  Total Tokens: {summary['total_tokens']:,}")
        print(f"  Total Cost: ${summary['total_cost']:.6f}")
        print(f"  Average Cost per Request: ${summary['average_cost_per_request']:.6f}")
        
        # Per-request breakdown
        if len(usages) <= 10:
            print(f"\nPer-Request Breakdown:")
            for i, usage in enumerate(usages, 1):
                cost = calculate_cost_from_usage(usage, model)
                print(f"  Request {i}:")
                print(f"    Tokens: {cost['total_tokens']} (prompt: {cost['prompt_tokens']}, completion: {cost['completion_tokens']})")
                print(f"    Cost: ${cost['total_cost']:.6f}")
        
    except subprocess.TimeoutExpired:
        print("Error: Timeout getting logs")
    except FileNotFoundError:
        print("Error: Docker not found. Make sure Docker is installed and accessible.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Track MLflow Gateway costs")
    parser.add_argument("--container", default="mlflow-gateway", help="Docker container name")
    parser.add_argument("--model", default="gpt-3.5-turbo", help="Model name for pricing")
    parser.add_argument("--log-file", help="Path to log file (alternative to Docker logs)")
    
    args = parser.parse_args()
    
    if args.log_file:
        usages = extract_usage_from_logs(args.log_file)
        if usages:
            summary = aggregate_costs(usages, args.model)
            print(json.dumps(summary, indent=2))
    else:
        track_costs_from_docker_logs(args.container, args.model)

