#!/bin/bash

###############################################################################
# VPS Integration Setup Script
# 
# This script sets up the VPS integration environment including:
# - Python virtual environment
# - Required dependencies
# - SSL certificates
# - Configuration files
# - System service
# - Security hardening
#
# Author: Organiser
# Date: 2026-03-05
###############################################################################

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo_error "This script must be run as root"
    exit 1
fi

echo_info "Starting VPS Integration Setup..."

# Variables
INSTALL_DIR="/opt/vps-integration"
CONFIG_DIR="/etc/vps-integration"
LOG_DIR="/var/log/vps-integration"
SSL_DIR="${CONFIG_DIR}/ssl"
VPS_USER="vps-api"
VPS_PORT="5000"

# Create directories
echo_info "Creating directories..."
mkdir -p "${INSTALL_DIR}"
mkdir -p "${CONFIG_DIR}"
mkdir -p "${LOG_DIR}"
mkdir -p "${SSL_DIR}"

# Create dedicated user
echo_info "Creating dedicated user..."
if ! id "${VPS_USER}" &>/dev/null; then
    useradd -r -s /bin/false -d "${INSTALL_DIR}" "${VPS_USER}"
    echo_info "User ${VPS_USER} created"
else
    echo_warn "User ${VPS_USER} already exists"
fi

# Install system dependencies
echo_info "Installing system dependencies..."
if command -v apt-get &> /dev/null; then
    apt-get update
    apt-get install -y python3 python3-pip python3-venv openssl curl git
elif command -v yum &> /dev/null; then
    yum install -y python3 python3-pip openssl curl git
elif command -v dnf &> /dev/null; then
    dnf install -y python3 python3-pip openssl curl git
else
    echo_error "Unsupported package manager"
    exit 1
fi

# Create Python virtual environment
echo_info "Creating Python virtual environment..."
python3 -m venv "${INSTALL_DIR}/venv"
source "${INSTALL_DIR}/venv/bin/activate"

# Install Python dependencies
echo_info "Installing Python dependencies..."
pip install --upgrade pip
pip install flask flask-limiter pyjwt cryptography gunicorn

# Copy application files
echo_info "Copying application files..."
cp vps_api_server.py "${INSTALL_DIR}/"
cp auth_manager.py "${INSTALL_DIR}/"
chmod +x "${INSTALL_DIR}/vps_api_server.py"
chmod +x "${INSTALL_DIR}/auth_manager.py"

# Generate SSL certificates (self-signed)
echo_info "Generating SSL certificates..."
if [ ! -f "${SSL_DIR}/cert.pem" ]; then
    openssl req -x509 -newkey rsa:4096 -nodes \
        -out "${SSL_DIR}/cert.pem" \
        -keyout "${SSL_DIR}/key.pem" \
        -days 365 \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=vps-api.local"
    echo_info "SSL certificates generated"
else
    echo_warn "SSL certificates already exist"
fi

# Generate secret key
echo_info "Generating secret key..."
SECRET_KEY=$(openssl rand -hex 32)

# Create configuration file
echo_info "Creating configuration file..."
cat > "${CONFIG_DIR}/config.json" <<EOF
{
    "host": "0.0.0.0",
    "port": ${VPS_PORT},
    "debug": false,
    "ssl_enabled": true,
    "ssl_cert": "${SSL_DIR}/cert.pem",
    "ssl_key": "${SSL_DIR}/key.pem",
    "secret_key": "${SECRET_KEY}"
}
EOF

# Create initial auth tokens file
echo_info "Creating auth tokens file..."
cat > "${CONFIG_DIR}/auth_tokens.json" <<EOF
{
    "example-client": {
        "api_key_hash": "changeme",
        "permissions": ["read", "execute", "install"],
        "description": "Example client - change this!",
        "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    }
}
EOF

# Create command whitelist
echo_info "Creating command whitelist..."
cat > "${CONFIG_DIR}/command_whitelist.json" <<EOF
{
    "commands": [
        "ls -la",
        "pwd",
        "whoami",
        "docker ps",
        "docker images",
        "git status",
        "systemctl status",
        "df -h",
        "free -m",
        "ps aux"
    ],
    "description": "Whitelist of allowed commands. If empty, default allowed commands are used."
}
EOF

# Create systemd service
echo_info "Creating systemd service..."
cat > /etc/systemd/system/vps-api.service <<EOF
[Unit]
Description=VPS API Server
After=network.target

[Service]
Type=simple
User=${VPS_USER}
Group=${VPS_USER}
WorkingDirectory=${INSTALL_DIR}
Environment="PATH=${INSTALL_DIR}/venv/bin"
Environment="VPS_CONFIG_PATH=${CONFIG_DIR}/config.json"
Environment="VPS_LOG_PATH=${LOG_DIR}/api.log"
Environment="VPS_AUTH_PATH=${CONFIG_DIR}/auth_tokens.json"
Environment="VPS_WHITELIST_PATH=${CONFIG_DIR}/command_whitelist.json"
ExecStart=${INSTALL_DIR}/venv/bin/gunicorn \
    --bind 0.0.0.0:${VPS_PORT} \
    --workers 4 \
    --timeout 120 \
    --access-logfile ${LOG_DIR}/access.log \
    --error-logfile ${LOG_DIR}/error.log \
    --certfile ${SSL_DIR}/cert.pem \
    --keyfile ${SSL_DIR}/key.pem \
    vps_api_server:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
echo_info "Setting permissions..."
chown -R "${VPS_USER}:${VPS_USER}" "${INSTALL_DIR}"
chown -R "${VPS_USER}:${VPS_USER}" "${CONFIG_DIR}"
chown -R "${VPS_USER}:${VPS_USER}" "${LOG_DIR}"
chmod 600 "${CONFIG_DIR}/config.json"
chmod 600 "${CONFIG_DIR}/auth_tokens.json"
chmod 600 "${SSL_DIR}/key.pem"
chmod 644 "${SSL_DIR}/cert.pem"

# Configure firewall (if ufw is available)
if command -v ufw &> /dev/null; then
    echo_info "Configuring firewall..."
    ufw allow ${VPS_PORT}/tcp
    echo_info "Firewall rule added for port ${VPS_PORT}"
fi

# Enable and start service
echo_info "Enabling and starting service..."
systemctl daemon-reload
systemctl enable vps-api.service
systemctl start vps-api.service

# Wait a moment and check status
sleep 2
if systemctl is-active --quiet vps-api.service; then
    echo_info "Service is running"
else
    echo_error "Service failed to start. Check logs: journalctl -u vps-api.service"
    exit 1
fi

# Create log rotation
echo_info "Setting up log rotation..."
cat > /etc/logrotate.d/vps-api <<EOF
${LOG_DIR}/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 ${VPS_USER} ${VPS_USER}
    sharedscripts
    postrotate
        systemctl reload vps-api.service > /dev/null 2>&1 || true
    endscript
}
EOF

echo ""
echo_info "========================================"
echo_info "VPS Integration Setup Complete!"
echo_info "========================================"
echo ""
echo_info "Server is running on: https://0.0.0.0:${VPS_PORT}"
echo_info "Configuration: ${CONFIG_DIR}/config.json"
echo_info "Logs: ${LOG_DIR}/"
echo_info "Service: systemctl status vps-api.service"
echo ""
echo_warn "IMPORTANT: Update auth tokens before production use!"
echo_warn "Run: ${INSTALL_DIR}/auth_manager.py add-client <client_name>"
echo ""
echo_info "Next steps:"
echo_info "1. Generate API credentials: ${INSTALL_DIR}/venv/bin/python ${INSTALL_DIR}/auth_manager.py add-client poke"
echo_info "2. Configure your firewall to restrict access"
echo_info "3. Update command whitelist: ${CONFIG_DIR}/command_whitelist.json"
echo_info "4. Review security settings"
echo_info "5. Test the API: curl -k https://localhost:${VPS_PORT}/health"
echo ""
