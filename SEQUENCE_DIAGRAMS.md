# SEQUENCE DIAGRAMS - MLFLOW AI GATEWAY

## 📊 Sequence Diagram 1: Deploy và Mở Rộng

```mermaid
sequenceDiagram
    participant User
    participant Docker
    participant Gateway
    participant Nginx
    participant OpenAI

    Note over User,OpenAI: DEPLOY DEVELOPMENT
    User->>Docker: docker compose up -d
    Docker->>Gateway: Start container
    Gateway->>Gateway: Health check
    Gateway-->>User: ✅ Running

    Note over User,OpenAI: SCALE PRODUCTION
    User->>Docker: docker compose -f prod.yml up -d --scale mlflow-gateway=3
    Docker->>Gateway: Start 3 instances
    Docker->>Nginx: Start load balancer
    Gateway-->>Docker: All healthy
    Nginx-->>User: ✅ 3 instances + nginx

    Note over User,OpenAI: REQUEST FLOW
    User->>Nginx: POST /gateway/chat/invocations
    Nginx->>Gateway: Forward (round-robin)
    Gateway->>OpenAI: API call
    OpenAI-->>Gateway: Response + usage
    Gateway-->>Nginx: Response
    Nginx-->>User: Response
```

---

## 📊 Sequence Diagram 2: Đánh Giá API Gateway

```mermaid
sequenceDiagram
    participant User
    participant Script
    participant Gateway
    participant OpenAI
    participant File

    User->>Script: python3 evaluate_gateway.py
    
    Note over Script,Gateway: HEALTH CHECK
    Script->>Gateway: GET /health
    Gateway-->>Script: {"status":"OK"}
    
    Note over Script,OpenAI: TEST 1: SIMPLE QUESTION
    Script->>Gateway: POST /gateway/chat/invocations
    Gateway->>OpenAI: API call
    OpenAI-->>Gateway: Response + usage
    Gateway-->>Script: {choices, usage: {tokens}}
    Script->>Script: Calculate cost
    Script-->>User: ✓ Test 1: $0.000090
    
    Note over Script,OpenAI: TEST 2: MULTI-TURN
    Script->>Gateway: POST /gateway/chat/invocations
    Gateway->>OpenAI: API call
    OpenAI-->>Gateway: Response + usage
    Gateway-->>Script: {choices, usage: {tokens}}
    Script->>Script: Calculate cost
    Script-->>User: ✓ Test 2: $0.000179
    
    Note over Script,File: SAVE RESULTS
    Script->>File: Save gateway_results.json
    Script-->>User: ✓ Total: $0.000269
```

---

## 📊 Sequence Diagram 3: Logging và Phân Tích Chi Phí

```mermaid
sequenceDiagram
    participant User
    participant Script
    participant Gateway
    participant File
    participant Logs

    Note over User,Logs: LOGGING
    Gateway->>Logs: Log requests/responses
    Gateway->>File: Save gateway_results.json
    
    Note over User,File: ANALYZE COSTS
    User->>Script: python3 analyze_costs.py --response-file gateway_results.json
    Script->>File: Read results
    File-->>Script: {total_requests, total_cost, results[]}
    Script->>Script: Parse usage data
    Script->>Script: Calculate costs
    Script-->>User: Total: 2 requests, $0.000269
    
    Note over User,Logs: ALTERNATIVE: FROM LOGS
    User->>Script: python3 analyze_costs.py --container mlflow-gateway
    Script->>Logs: Read Docker logs
    alt Usage data found
        Logs-->>Script: Usage data
        Script->>Script: Calculate costs
        Script-->>User: Cost analysis
    else No data
        Script->>File: Auto-detect results file
        File-->>Script: gateway_results.json
        Script-->>User: Cost analysis from file
    end
```

---

## 📊 Sequence Diagram: Tổng Hợp 3 Yêu Cầu

```mermaid
sequenceDiagram
    participant User
    participant Docker
    participant Gateway
    participant EvalScript
    participant CostScript
    participant OpenAI
    participant File

    Note over User,File: YÊU CẦU 1: DEPLOY & SCALE
    User->>Docker: docker compose up -d
    Docker->>Gateway: Start
    Gateway-->>User: ✅ Deployed
    
    User->>Docker: docker compose -f prod.yml up -d --scale mlflow-gateway=3
    Docker->>Gateway: Scale to 3 instances
    Gateway-->>User: ✅ Scaled
    
    Note over User,File: YÊU CẦU 2: EVALUATE
    User->>EvalScript: python3 evaluate_gateway.py
    EvalScript->>Gateway: Health check
    Gateway-->>EvalScript: OK
    EvalScript->>Gateway: Test requests
    Gateway->>OpenAI: API calls
    OpenAI-->>Gateway: Responses + usage
    Gateway-->>EvalScript: Results
    EvalScript->>File: Save gateway_results.json
    EvalScript-->>User: ✅ Evaluation complete
    
    Note over User,File: YÊU CẦU 3: LOGGING & COSTS
    Gateway->>File: Log requests
    User->>CostScript: python3 analyze_costs.py --response-file gateway_results.json
    CostScript->>File: Read results
    File-->>CostScript: Data
    CostScript->>CostScript: Calculate costs
    CostScript-->>User: ✅ Cost analysis
```

---

## 📊 Sequence Diagram: Request Flow Chi Tiết

```mermaid
sequenceDiagram
    participant Client
    participant Nginx
    participant Gateway
    participant OpenAI

    Client->>Nginx: POST /gateway/chat/invocations
    Nginx->>Gateway: Forward request
    Gateway->>OpenAI: API call
    OpenAI-->>Gateway: Response + usage<br/>{prompt_tokens, completion_tokens}
    Gateway->>Gateway: Log request
    Gateway-->>Nginx: Response
    Nginx->>Nginx: Log access
    Nginx-->>Client: Response
```

---

## 📊 Sequence Diagram: Cost Calculation

```mermaid
sequenceDiagram
    participant Response
    participant Parser
    participant Calculator
    participant Output

    Response->>Parser: {usage: {prompt_tokens: 15, completion_tokens: 45}}
    Parser->>Calculator: Extract tokens
    Calculator->>Calculator: input_cost = (15/1000) × $0.0005
    Calculator->>Calculator: output_cost = (45/1000) × $0.0015
    Calculator->>Calculator: total = $0.000075
    Calculator->>Output: Display cost
    Output-->>Output: $0.000075
```

---

## 📝 Ghi Chú

### Các thành phần:
- **User**: Developer/User
- **Docker**: Docker Compose
- **Gateway**: MLflow Gateway
- **Nginx**: Load balancer
- **OpenAI**: External API
- **Script**: Python scripts
- **File**: Results file
- **Logs**: Docker logs

### Cách xem:
1. **VS Code**: Cài extension "Markdown Preview Mermaid Support"
2. **Online**: https://mermaid.live/
3. **GitHub/GitLab**: Xem trực tiếp (hỗ trợ Mermaid)

---

## 🎯 Tóm Tắt 3 Yêu Cầu

```mermaid
graph LR
    A[Yêu Cầu 1:<br/>Deploy & Scale] --> B[Yêu Cầu 2:<br/>Evaluate]
    B --> C[Yêu Cầu 3:<br/>Logging & Costs]
    
    A --> A1[docker compose up -d]
    A --> A2[Scale to 3 instances]
    
    B --> B1[Health check]
    B --> B2[Test requests]
    B --> B3[Save results]
    
    C --> C1[Log requests]
    C --> C2[Analyze costs]
    C --> C3[Display statistics]
```
