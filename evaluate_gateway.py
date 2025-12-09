#!/usr/bin/env python3
"""
MLflow Gateway Evaluation Script
Đánh giá API Gateway với requests thực tế và track costs
"""

import requests
import json
import sys
import time
import os
from datetime import datetime
from typing import Dict, Any, Optional

# Configuration
GATEWAY_URL = os.getenv("GATEWAY_URL", "http://localhost:5000")
ENDPOINT = "/gateway/chat/invocations"
TIMEOUT = int(os.getenv("REQUEST_TIMEOUT", "60"))

class GatewayEvaluator:
    def __init__(self, gateway_url: str = GATEWAY_URL):
        self.gateway_url = gateway_url
        self.endpoint = f"{gateway_url}{ENDPOINT}"
        self.results = []
        
    def check_health(self) -> bool:
        """Kiểm tra health endpoint"""
        try:
            response = requests.get(f"{self.gateway_url}/health", timeout=5)
            if response.status_code == 200:
                print(f"✓ Health check passed: {response.json()}")
                return True
            else:
                print(f"✗ Health check failed: {response.status_code}")
                return False
        except Exception as e:
            print(f"✗ Health check error: {e}")
            return False
    
    def send_request(self, messages: list, temperature: float = 0.7, max_tokens: int = 500) -> Optional[Dict[str, Any]]:
        """Gửi request đến gateway và trả về response với usage info"""
        headers = {"Content-Type": "application/json"}
        payload = {
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens
        }
        
        start_time = time.time()
        try:
            response = requests.post(self.endpoint, headers=headers, json=payload, timeout=TIMEOUT)
            elapsed_time = time.time() - start_time
            
            result = {
                "status_code": response.status_code,
                "response_time": elapsed_time,
                "timestamp": datetime.now().isoformat()
            }
            
            if response.status_code == 200:
                data = response.json()
                result["success"] = True
                result["response"] = data
                
                # Extract usage if available
                if "usage" in data:
                    result["usage"] = data["usage"]
                elif "choices" in data and len(data["choices"]) > 0:
                    # Try to extract from choices
                    choice = data["choices"][0]
                    if "usage" in choice:
                        result["usage"] = choice["usage"]
                
                # Extract message content
                if "choices" in data and len(data["choices"]) > 0:
                    message = data["choices"][0].get("message", {})
                    result["content"] = message.get("content", "")
            else:
                result["success"] = False
                result["error"] = response.text
                
            self.results.append(result)
            return result
            
        except requests.exceptions.Timeout:
            result = {
                "success": False,
                "error": f"Request timeout after {TIMEOUT}s",
                "status_code": 0,
                "response_time": TIMEOUT,
                "timestamp": datetime.now().isoformat()
            }
            self.results.append(result)
            return result
        except Exception as e:
            result = {
                "success": False,
                "error": str(e),
                "status_code": 0,
                "response_time": 0,
                "timestamp": datetime.now().isoformat()
            }
            self.results.append(result)
            return result
    
    def calculate_cost(self, usage: Dict[str, Any], model: str = "gpt-3.5-turbo") -> Dict[str, float]:
        """Tính toán chi phí dựa trên token usage"""
        pricing = {
            "gpt-3.5-turbo": {"input": 0.0005, "output": 0.0015},
            "gpt-4": {"input": 0.03, "output": 0.06},
            "gpt-4-turbo": {"input": 0.01, "output": 0.03},
            "gpt-4o": {"input": 0.005, "output": 0.015}
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
    
    def evaluate(self, test_cases: list = None):
        """Chạy evaluation với test cases"""
        print("=" * 70)
        print("MLflow Gateway Evaluation")
        print(f"Gateway URL: {self.gateway_url}")
        print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 70)
        
        # Health check
        if not self.check_health():
            print("\n✗ Gateway health check failed. Exiting.")
            sys.exit(1)
        
        # Default test cases
        if test_cases is None:
            test_cases = [
                {
                    "name": "Simple Question",
                    "messages": [{"role": "user", "content": "What is artificial intelligence?"}],
                    "temperature": 0.7,
                    "max_tokens": 200
                },
                {
                    "name": "Multi-turn Conversation",
                    "messages": [
                        {"role": "user", "content": "Explain machine learning"},
                        {"role": "assistant", "content": "Machine learning is a method of data analysis."},
                        {"role": "user", "content": "Give me a practical example"}
                    ],
                    "temperature": 0.7,
                    "max_tokens": 300
                }
            ]
        
        # Run test cases
        total_cost = 0.0
        successful_requests = 0
        
        for i, test_case in enumerate(test_cases, 1):
            print(f"\n{'=' * 70}")
            print(f"Test {i}: {test_case['name']}")
            print(f"{'=' * 70}")
            
            result = self.send_request(
                test_case["messages"],
                test_case.get("temperature", 0.7),
                test_case.get("max_tokens", 500)
            )
            
            if result["success"]:
                successful_requests += 1
                print(f"✓ Request successful (Status: {result['status_code']}, Time: {result['response_time']:.2f}s)")
                
                if "usage" in result:
                    usage = result["usage"]
                    cost = self.calculate_cost(usage)
                    total_cost += cost["total_cost"]
                    
                    print(f"\nToken Usage:")
                    print(f"  Prompt: {usage.get('prompt_tokens', 0)}")
                    print(f"  Completion: {usage.get('completion_tokens', 0)}")
                    print(f"  Total: {usage.get('total_tokens', 0)}")
                    print(f"  Cost: ${cost['total_cost']:.6f}")
                    
                    if "content" in result:
                        content = result["content"]
                        print(f"\nResponse Preview: {content[:100]}...")
                else:
                    print("⚠ No usage information in response")
            else:
                print(f"✗ Request failed: {result.get('error', 'Unknown error')}")
        
        # Summary
        print(f"\n{'=' * 70}")
        print("Evaluation Summary")
        print(f"{'=' * 70}")
        print(f"Total Requests: {len(test_cases)}")
        print(f"Successful: {successful_requests}")
        print(f"Failed: {len(test_cases) - successful_requests}")
        print(f"Total Cost: ${total_cost:.6f}")
        if successful_requests > 0:
            print(f"Average Cost per Request: ${total_cost / successful_requests:.6f}")
        else:
            print("Average Cost per Request: N/A (no successful requests)")
            print("\n⚠ All requests failed. Check:")
            print("  1. API key is valid (not placeholder)")
            print("  2. Gateway is running correctly")
            print("  3. Network connectivity")
        
        return {
            "total_requests": len(test_cases),
            "successful": successful_requests,
            "failed": len(test_cases) - successful_requests,
            "total_cost": total_cost,
            "results": self.results
        }

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Evaluate MLflow Gateway")
    parser.add_argument("--url", default=GATEWAY_URL, help="Gateway URL")
    parser.add_argument("--test-file", help="JSON file with test cases")
    parser.add_argument("--output", help="Output file for results (JSON)")
    
    args = parser.parse_args()
    
    evaluator = GatewayEvaluator(args.url)
    
    # Load test cases from file if provided
    test_cases = None
    if args.test_file:
        try:
            with open(args.test_file, 'r') as f:
                test_cases = json.load(f)
        except FileNotFoundError:
            print(f"✗ Error: Test file not found: {args.test_file}")
            print("  Create a JSON file with test cases, example:")
            print('  [{"name": "Test", "messages": [{"role": "user", "content": "Hello"}]}]')
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"✗ Error: Invalid JSON in test file: {e}")
            sys.exit(1)
    
    # Run evaluation
    try:
        summary = evaluator.evaluate(test_cases)
        
        # Save results if output file specified
        if args.output:
            try:
                with open(args.output, 'w') as f:
                    json.dump(summary, f, indent=2)
                print(f"\n✓ Results saved to {args.output}")
            except Exception as e:
                print(f"✗ Error saving results: {e}")
    except KeyboardInterrupt:
        print("\n\n⚠ Evaluation interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n✗ Evaluation error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

