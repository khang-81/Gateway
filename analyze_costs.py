#!/usr/bin/env python3
"""
MLflow Gateway Cost Analysis Script
Phân tích chi phí từ Docker logs hoặc response files
"""

import json
import re
import sys
import subprocess
from datetime import datetime
from typing import Dict, List, Any
from collections import defaultdict

# Pricing per 1K tokens (2024)
PRICING = {
    "gpt-3.5-turbo": {"input": 0.0005, "output": 0.0015},
    "gpt-4": {"input": 0.03, "output": 0.06},
    "gpt-4-turbo": {"input": 0.01, "output": 0.03},
    "gpt-4o": {"input": 0.005, "output": 0.015}
}

def parse_log_line(line: str) -> Dict[str, Any]:
    """Parse JSON từ log line"""
    json_match = re.search(r'\{.*\}', line, re.DOTALL)
    if not json_match:
        return None
    
    try:
        return json.loads(json_match.group())
    except:
        return None

def extract_usage_from_response(response_data: Dict[str, Any]) -> Dict[str, Any]:
    """Extract usage từ response data"""
    if "usage" in response_data:
        return response_data["usage"]
    elif "choices" in response_data and len(response_data["choices"]) > 0:
        choice = response_data["choices"][0]
        if "usage" in choice:
            return choice["usage"]
    return None

def calculate_cost(usage: Dict[str, Any], model: str = "gpt-3.5-turbo") -> Dict[str, float]:
    """Tính toán chi phí"""
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

def analyze_docker_logs(container_name: str = "mlflow-gateway", model: str = "gpt-3.5-turbo", tail: int = 1000):
    """Phân tích costs từ Docker logs"""
    print("=" * 70)
    print("MLflow Gateway Cost Analysis")
    print(f"Container: {container_name}")
    print(f"Model: {model}")
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)
    
    try:
        result = subprocess.run(
            ["docker", "logs", container_name, "--tail", str(tail)],
            capture_output=True,
            text=True,
            timeout=15
        )
        
        if result.returncode != 0:
            print(f"✗ Error getting logs: {result.stderr}")
            return
        
        logs = result.stdout
        usages = []
        
        # Parse logs
        for line in logs.split('\n'):
            if any(kw in line.lower() for kw in ['usage', 'token', 'prompt_tokens', 'completion_tokens']):
                data = parse_log_line(line)
                if data:
                    usage = extract_usage_from_response(data)
                    if usage:
                        usages.append(usage)
                else:
                    # Regex fallback
                    prompt_match = re.search(r'["\']?prompt_tokens["\']?\s*[:=]\s*(\d+)', line, re.IGNORECASE)
                    completion_match = re.search(r'["\']?completion_tokens["\']?\s*[:=]\s*(\d+)', line, re.IGNORECASE)
                    
                    if prompt_match or completion_match:
                        usage_data = {
                            "prompt_tokens": int(prompt_match.group(1)) if prompt_match else 0,
                            "completion_tokens": int(completion_match.group(1)) if completion_match else 0
                        }
                        usage_data["total_tokens"] = usage_data["prompt_tokens"] + usage_data["completion_tokens"]
                        if usage_data["total_tokens"] > 0:
                            usages.append(usage_data)
        
        if not usages:
            print("\n⚠ No usage data found in logs.")
            print("Make sure you have sent requests to the gateway.")
            print("Usage data appears in logs after successful API calls.")
            return
        
        # Calculate costs
        total_prompt = sum(u.get("prompt_tokens", 0) for u in usages)
        total_completion = sum(u.get("completion_tokens", 0) for u in usages)
        total_tokens = total_prompt + total_completion
        total_cost = sum(calculate_cost(u, model)["total_cost"] for u in usages)
        
        print(f"\n{'=' * 70}")
        print("Cost Summary")
        print(f"{'=' * 70}")
        print(f"Total Requests: {len(usages)}")
        print(f"Total Prompt Tokens: {total_prompt:,}")
        print(f"Total Completion Tokens: {total_completion:,}")
        print(f"Total Tokens: {total_tokens:,}")
        print(f"Total Cost: ${total_cost:.6f}")
        print(f"Average Cost per Request: ${total_cost / len(usages):.6f}")
        
        # Per-request breakdown (if <= 20 requests)
        if len(usages) <= 20:
            print(f"\n{'=' * 70}")
            print("Per-Request Breakdown")
            print(f"{'=' * 70}")
            for i, usage in enumerate(usages, 1):
                cost = calculate_cost(usage, model)
                print(f"\nRequest {i}:")
                print(f"  Tokens: {cost['total_tokens']} (prompt: {cost['prompt_tokens']}, completion: {cost['completion_tokens']})")
                print(f"  Cost: ${cost['total_cost']:.6f}")
        
    except subprocess.TimeoutExpired:
        print("✗ Error: Timeout getting logs")
    except FileNotFoundError:
        print("✗ Error: Docker not found")
    except Exception as e:
        print(f"✗ Error: {e}")

def analyze_response_file(file_path: str, model: str = "gpt-3.5-turbo"):
    """Phân tích costs từ response file (JSON)"""
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
        
        # Handle different formats
        if isinstance(data, list):
            responses = data
        elif "results" in data:
            responses = data["results"]
        else:
            responses = [data]
        
        usages = []
        for response in responses:
            if isinstance(response, dict):
                usage = extract_usage_from_response(response)
                if usage:
                    usages.append(usage)
        
        if not usages:
            print("⚠ No usage data found in file")
            return
        
        # Calculate and display
        total_prompt = sum(u.get("prompt_tokens", 0) for u in usages)
        total_completion = sum(u.get("completion_tokens", 0) for u in usages)
        total_tokens = total_prompt + total_completion
        total_cost = sum(calculate_cost(u, model)["total_cost"] for u in usages)
        
        print("=" * 70)
        print("Cost Analysis from Response File")
        print("=" * 70)
        print(f"Total Requests: {len(usages)}")
        print(f"Total Prompt Tokens: {total_prompt:,}")
        print(f"Total Completion Tokens: {total_completion:,}")
        print(f"Total Tokens: {total_tokens:,}")
        print(f"Total Cost: ${total_cost:.6f}")
        if len(usages) > 0:
            print(f"Average Cost per Request: ${total_cost / len(usages):.6f}")
        
    except FileNotFoundError:
        print(f"✗ File not found: {file_path}")
        print("  Make sure the file exists and path is correct")
    except json.JSONDecodeError as e:
        print(f"✗ Invalid JSON file: {file_path}")
        print(f"  Error: {e}")
    except Exception as e:
        print(f"✗ Error: {e}")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Analyze MLflow Gateway costs")
    parser.add_argument("--container", default="mlflow-gateway", help="Docker container name")
    parser.add_argument("--model", default="gpt-3.5-turbo", help="Model for pricing")
    parser.add_argument("--log-file", help="Path to log file")
    parser.add_argument("--response-file", help="Path to response JSON file")
    parser.add_argument("--tail", type=int, default=1000, help="Number of log lines to analyze")
    
    args = parser.parse_args()
    
    if args.response_file:
        analyze_response_file(args.response_file, args.model)
    elif args.log_file:
        # Read from log file
        with open(args.log_file, 'r') as f:
            logs = f.read()
        # Similar parsing logic...
        print("Log file analysis not fully implemented. Use --container instead.")
    else:
        analyze_docker_logs(args.container, args.model, args.tail)

if __name__ == "__main__":
    main()

