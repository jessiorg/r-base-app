# R Base API Application - Production Ready

![R](https://img.shields.io/badge/R-4.4+-276DC3)
![Plumber](https://img.shields.io/badge/Plumber-API-blue)
![Docker](https://img.shields.io/badge/Docker-Enabled-blue)
![REST](https://img.shields.io/badge/REST-API-green)

## 🚀 Overview

A production-ready R-based REST API using Plumber for data analysis, statistical computations, and trading calculations. Designed for high-performance analytical endpoints with Docker deployment and Nginx reverse proxy.

## ✨ Features

- **Plumber API**: High-performance REST API framework for R
- **Statistical Analysis**: Advanced statistical computations
- **Trading Calculations**: Financial metrics and indicators
- **Data Processing**: ETL and data transformation endpoints
- **Time Series Analysis**: Forecasting and trend analysis
- **Docker Deployment**: Complete containerized setup
- **Nginx Reverse Proxy**: Secure access at /r-api/ path
- **Auto Documentation**: Swagger UI included
- **Production Ready**: Error handling, logging, rate limiting

## 📚 API Endpoints

### Core Endpoints

#### Health Check
```bash
GET /r-api/health
```

#### API Documentation
```bash
GET /r-api/__docs__/
```

### Statistical Analysis

#### Descriptive Statistics
```bash
POST /r-api/stats/describe
Content-Type: application/json

{
  "data": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
}
```

#### Correlation Analysis
```bash
POST /r-api/stats/correlation
Content-Type: application/json

{
  "x": [1, 2, 3, 4, 5],
  "y": [2, 4, 5, 4, 5]
}
```

#### Linear Regression
```bash
POST /r-api/stats/regression
Content-Type: application/json

{
  "x": [1, 2, 3, 4, 5],
  "y": [2, 4, 5, 4, 5]
}
```

### Trading & Financial

#### Calculate Returns
```bash
POST /r-api/trading/returns
Content-Type: application/json

{
  "prices": [100, 102, 101, 105, 103],
  "type": "simple"  # or "log"
}
```

#### Moving Average
```bash
POST /r-api/trading/moving-average
Content-Type: application/json

{
  "prices": [100, 102, 101, 105, 103, 106, 104],
  "period": 3,
  "type": "simple"  # or "exponential"
}
```

#### RSI (Relative Strength Index)
```bash
POST /r-api/trading/rsi
Content-Type: application/json

{
  "prices": [44, 44.34, 44.09, 43.61, 44.33, 44.83],
  "period": 14
}
```

#### Volatility
```bash
POST /r-api/trading/volatility
Content-Type: application/json

{
  "returns": [0.01, -0.02, 0.015, -0.01, 0.02],
  "annualize": true
}
```

#### Sharpe Ratio
```bash
POST /r-api/trading/sharpe-ratio
Content-Type: application/json

{
  "returns": [0.01, -0.02, 0.015, -0.01, 0.02],
  "risk_free_rate": 0.02
}
```

### Time Series

#### Forecast (ARIMA)
```bash
POST /r-api/timeseries/forecast
Content-Type: application/json

{
  "data": [100, 102, 101, 105, 103, 106, 104, 108],
  "periods": 3,
  "method": "arima"
}
```

#### Decomposition
```bash
POST /r-api/timeseries/decompose
Content-Type: application/json

{
  "data": [100, 102, 101, 105, 103, 106, 104, 108],
  "frequency": 4,
  "type": "additive"  # or "multiplicative"
}
```

### Data Processing

#### Outlier Detection
```bash
POST /r-api/data/outliers
Content-Type: application/json

{
  "data": [1, 2, 3, 4, 5, 100, 6, 7],
  "method": "iqr"  # or "zscore"
}
```

#### Normalization
```bash
POST /r-api/data/normalize
Content-Type: application/json

{
  "data": [1, 2, 3, 4, 5],
  "method": "minmax"  # or "zscore"
}
```

## 📁 Architecture

```
/data/
├── docker/
│   ├── nginx/
│   │   └── conf.d/
│   │       └── r-api.conf          # Nginx config
│   └── docker-compose.yml          # Main compose file
└── r-api/                          # R API backend
    ├── api/
    │   ├── plumber.R               # Main API file
    │   ├── endpoints/
    │   │   ├── stats.R
    │   │   ├── trading.R
    │   │   ├── timeseries.R
    │   │   └── data.R
    │   └── utils/
    │       └── helpers.R
    ├── Dockerfile
    └── requirements.R
```

## 🛠️ Installation

### Prerequisites

- Docker 24.0+
- Docker Compose 2.20+
- Minimum 2GB RAM
- 5GB free disk space

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/jessiorg/r-base-app.git
   cd r-base-app
   ```

2. **Run the deployment script**
   ```bash
   sudo chmod +x scripts/deploy.sh
   sudo ./scripts/deploy.sh
   ```

3. **Test the API**
   ```bash
   # Health check
   curl http://localhost:8002/health
   
   # View API documentation
   open http://localhost:8002/__docs__/
   ```

### Manual Installation

1. **Set up directory structure**
   ```bash
   sudo mkdir -p /data/r-api/{api,logs}
   sudo mkdir -p /data/docker/nginx/conf.d
   ```

2. **Copy files**
   ```bash
   sudo cp -r api/ /data/r-api/
   sudo cp Dockerfile /data/r-api/
   sudo cp nginx/r-api.conf /data/docker/nginx/conf.d/
   ```

3. **Deploy**
   ```bash
   cd /data/docker
   docker-compose up -d r-api
   docker-compose restart nginx
   ```

## 🌐 Usage Examples

### Python Client

```python
import requests
import json

base_url = "http://localhost:8002"

# Calculate statistics
data = {"data": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]}
response = requests.post(f"{base_url}/stats/describe", json=data)
print(response.json())

# Calculate moving average
prices = {"prices": [100, 102, 101, 105, 103], "period": 3}
response = requests.post(f"{base_url}/trading/moving-average", json=prices)
print(response.json())

# Forecast
ts_data = {"data": [100, 102, 101, 105, 103], "periods": 3}
response = requests.post(f"{base_url}/timeseries/forecast", json=ts_data)
print(response.json())
```

### JavaScript/Node.js

```javascript
const axios = require('axios');

const baseURL = 'http://localhost:8002';

// Calculate returns
const prices = {
  prices: [100, 102, 101, 105, 103],
  type: 'simple'
};

axios.post(`${baseURL}/trading/returns`, prices)
  .then(response => {
    console.log('Returns:', response.data);
  })
  .catch(error => {
    console.error('Error:', error.response.data);
  });

// Calculate RSI
const rsiData = {
  prices: [44, 44.34, 44.09, 43.61, 44.33, 44.83],
  period: 14
};

axios.post(`${baseURL}/trading/rsi`, rsiData)
  .then(response => {
    console.log('RSI:', response.data);
  });
```

### curl Examples

```bash
# Descriptive statistics
curl -X POST http://localhost:8002/stats/describe \
  -H "Content-Type: application/json" \
  -d '{"data": [1,2,3,4,5,6,7,8,9,10]}'

# Calculate volatility
curl -X POST http://localhost:8002/trading/volatility \
  -H "Content-Type: application/json" \
  -d '{"returns": [0.01,-0.02,0.015,-0.01,0.02], "annualize": true}'

# Detect outliers
curl -X POST http://localhost:8002/data/outliers \
  -H "Content-Type: application/json" \
  -d '{"data": [1,2,3,4,5,100,6,7], "method": "iqr"}'
```

## 🔧 Configuration

### Environment Variables

**.env file:**
```bash
# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
API_WORKERS=4
LOG_LEVEL=info

# R Configuration
R_MAX_VSIZE=4Gb
R_MAX_CONNECTIONS=128

# CORS
CORS_ORIGINS=http://localhost,https://your-domain.com

# Rate Limiting
RATE_LIMIT=100/minute
```

### Custom Endpoints

Add new endpoints by creating files in `api/endpoints/`:

```r
# api/endpoints/custom.R

#* Custom calculation
#* @param values:numeric Array of values
#* @post /custom/calculate
function(values) {
  result <- your_custom_function(values)
  return(list(
    success = TRUE,
    result = result
  ))
}
```

## 📊 Use Cases

### 1. Trading Bot Integration

```python
# Calculate indicators for trading decisions
def get_trading_signal(prices):
    # Get moving averages
    sma = requests.post(f"{api_url}/trading/moving-average",
                       json={"prices": prices, "period": 20}).json()
    
    # Get RSI
    rsi = requests.post(f"{api_url}/trading/rsi",
                       json={"prices": prices, "period": 14}).json()
    
    # Make decision
    if rsi['rsi'] < 30 and prices[-1] > sma['ma'][-1]:
        return "BUY"
    elif rsi['rsi'] > 70:
        return "SELL"
    return "HOLD"
```

### 2. Data Pipeline

```python
# ETL pipeline with R API
def process_market_data(raw_data):
    # Detect outliers
    clean_data = requests.post(f"{api_url}/data/outliers",
                              json={"data": raw_data, "method": "iqr"}).json()
    
    # Normalize
    normalized = requests.post(f"{api_url}/data/normalize",
                              json={"data": clean_data['clean_data']}).json()
    
    # Forecast
    forecast = requests.post(f"{api_url}/timeseries/forecast",
                            json={"data": normalized['normalized'], "periods": 5}).json()
    
    return forecast
```

### 3. Risk Analysis

```python
# Portfolio risk metrics
def calculate_portfolio_risk(returns):
    # Volatility
    vol = requests.post(f"{api_url}/trading/volatility",
                       json={"returns": returns, "annualize": True}).json()
    
    # Sharpe ratio
    sharpe = requests.post(f"{api_url}/trading/sharpe-ratio",
                          json={"returns": returns, "risk_free_rate": 0.02}).json()
    
    return {
        "volatility": vol['volatility'],
        "sharpe_ratio": sharpe['sharpe_ratio']
    }
```

## 🔒 Security

### API Authentication (Coming Soon)

```r
# Add to plumber.R
#* @filter auth
function(req, res) {
  token <- req$HTTP_AUTHORIZATION
  if (is.null(token) || !validate_token(token)) {
    res$status <- 401
    return(list(error = "Unauthorized"))
  }
  forward()
}
```

### Rate Limiting

Configured in Nginx:
```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
```

## 📝 Monitoring & Logging

### View Logs
```bash
# Container logs
docker-compose logs -f r-api

# API logs
docker exec r-api cat /var/log/plumber.log
```

### Health Monitoring
```bash
# Check API health
curl http://localhost:8002/health

# Container stats
docker stats r-api
```

## 🐛 Troubleshooting

### API Not Responding

```bash
# Check logs
docker-compose logs r-api

# Rebuild
docker-compose build --no-cache r-api
docker-compose up -d r-api
```

### Slow Responses

- Increase worker count
- Add caching layer
- Optimize R code
- Increase memory limits

### Package Installation Failed

```bash
# Access container
docker exec -it r-api bash

# Install manually
R -e "install.packages('package-name')"
```

## 🚀 Production Deployment

### 1. SSL/TLS
```bash
sudo certbot --nginx -d your-domain.com
```

### 2. Scaling
```yaml
# In docker-compose.yml
r-api:
  deploy:
    replicas: 3
```

### 3. Caching
Add Redis for response caching

### 4. Monitoring
Integrate with Prometheus/Grafana

## 📚 Documentation

- [Plumber Documentation](https://www.rplumber.io/)
- [R API Best Practices](https://www.rplumber.io/articles/)
- [Docker R Images](https://hub.docker.com/r/rocker/r-base)

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md)

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🙏 Acknowledgments

- [Plumber](https://www.rplumber.io/) - R API framework
- [Rocker Project](https://www.rocker-project.org/) - Docker images
- R Community

## 📧 Support

For issues: [Create an issue](https://github.com/jessiorg/r-base-app/issues)

---

**Version**: 1.0.0  
**Last Updated**: March 4, 2026  
**Maintained by**: Organiser (@jessiorg)