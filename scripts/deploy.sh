#!/bin/bash
# R API Deployment Script

set -e

echo "======================================"
echo "R API Deployment"
echo "======================================"
echo ""

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/..
" && pwd)"
DATA_DIR="/data"
R_API_DIR="${DATA_DIR}/r-api"
NGINX_CONF_DIR="${DATA_DIR}/docker/nginx/conf.d"
DOCKER_DIR="${DATA_DIR}/docker"

if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo or as root"
    exit 1
fi

create_dir() {
    if [ ! -d "$1" ]; then
        echo "Creating directory: $1"
        mkdir -p "$1"
    else
        echo "Directory exists: $1"
    fi
}

echo "Step 1: Creating directories..."
create_dir "${R_API_DIR}/api/endpoints"
create_dir "${R_API_DIR}/api/utils"
create_dir "${R_API_DIR}/logs"
create_dir "${NGINX_CONF_DIR}"

echo ""
echo "Step 2: Copying files..."
cp -rv "${REPO_DIR}/api/" "${R_API_DIR}/"
cp -v "${REPO_DIR}/Dockerfile" "${R_API_DIR}/"
cp -v "${REPO_DIR}/nginx/r-api.conf" "${NGINX_CONF_DIR}/"

echo ""
echo "Step 3: Checking docker-compose.yml..."
if [ -f "${DOCKER_DIR}/docker-compose.yml" ]; then
    if ! grep -q "r-api" "${DOCKER_DIR}/docker-compose.yml"; then
        echo "Adding r-api service..."
        cat "${REPO_DIR}/docker-compose.service.yml" >> "${DOCKER_DIR}/docker-compose.yml"
    else
        echo "r-api service already exists"
    fi
else
    echo "Creating docker-compose.yml..."
    cp -v "${REPO_DIR}/docker-compose.service.yml" "${DOCKER_DIR}/docker-compose.yml"
fi

echo ""
echo "Step 4: Setting permissions..."
chown -R $SUDO_USER:$SUDO_USER "${R_API_DIR}"
chmod -R 755 "${R_API_DIR}"

echo ""
echo "Step 5: Creating environment file..."
if [ ! -f "${R_API_DIR}/.env" ]; then
    cp -v "${REPO_DIR}/.env.example" "${R_API_DIR}/.env"
fi

echo ""
echo "Step 6: Building Docker image..."
cd "${DOCKER_DIR}"
docker-compose build r-api

echo ""
echo "Step 7: Starting service..."
docker-compose up -d r-api

echo ""
echo "Waiting for service..."
sleep 10

echo ""
echo "Step 8: Testing API..."
for i in {1..10}; do
    if curl -f http://localhost:8002/health > /dev/null 2>&1; then
        echo "✓ API is healthy!"
        break
    else
        echo "Waiting... (attempt $i/10)"
        sleep 3
    fi
    if [ $i -eq 10 ]; then
        echo "⚠ Health check failed. Check logs: docker-compose logs r-api"
    fi
done

echo ""
echo "Step 9: Restarting Nginx..."
docker-compose restart nginx || echo "Note: Nginx restart failed or not running"

echo ""
echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo ""
echo "API Documentation: http://your-domain.com/r-api/__docs__/"
echo "Health Check: http://your-domain.com/r-api/health"
echo ""
echo "Commands:"
echo "  Logs:    docker-compose logs -f r-api"
echo "  Restart: docker-compose restart r-api"
echo "  Stop:    docker-compose stop r-api"
echo ""