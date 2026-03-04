# R API - Quick Start Guide

## 5-Minute Setup

### 1. Clone and Deploy
```bash
git clone https://github.com/jessiorg/r-base-app.git
cd r-base-app
sudo chmod +x scripts/deploy.sh
sudo ./scripts/deploy.sh
```

### 2. Test API
```bash
# Health check
curl http://localhost:8002/health

# View documentation
open http://localhost:8002/__docs__/
```

### 3. First API Call

```bash
# Calculate statistics
curl -X POST http://localhost:8002/stats/describe \
  -H "Content-Type: application/json" \
  -d '{"data": [1,2,3,4,5,6,7,8,9,10]}'

# Calculate moving average
curl -X POST http://localhost:8002/trading/moving-average \
  -H "Content-Type: application/json" \
  -d '{"prices": [100,102,101,105,103], "period": 3}'
```

## Python Example

```python
import requests

url = "http://localhost:8002"

# Descriptive stats
response = requests.post(
    f"{url}/stats/describe",
    json={"data": [1, 2, 3, 4, 5]}
)
print(response.json())

# RSI calculation
response = requests.post(
    f"{url}/trading/rsi",
    json={"prices": [44, 44.34, 44.09, 43.61, 44.33], "period": 14}
)
print(response.json())
```

## Common Commands

```bash
# View logs
sudo docker logs r-api

# Restart
sudo docker-compose -f /data/docker/docker-compose.yml restart r-api

# Stop
sudo docker-compose -f /data/docker/docker-compose.yml stop r-api
```

## Troubleshooting

```bash
# Check if running
sudo docker ps | grep r-api

# View detailed logs
sudo docker logs r-api --tail 100

# Test direct access
curl http://localhost:8002/health
```

For full documentation, see [README.md](README.md)