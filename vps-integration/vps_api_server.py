#!/usr/bin/env python3
"""
VPS API Server for Oracle VPS Integration

This server provides a secure API endpoint for remote VPS management,
allowing Poke (via MCP) to connect and execute commands securely.

Author: Organiser
Date: 2026-03-05
"""

import os
import json
import logging
import subprocess
import secrets
import hashlib
import hmac
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from flask import Flask, request, jsonify
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from functools import wraps
import jwt
from cryptography.fernet import Fernet

# Configuration
CONFIG_PATH = Path(os.getenv('VPS_CONFIG_PATH', '/etc/vps-integration/config.json'))
LOG_PATH = Path(os.getenv('VPS_LOG_PATH', '/var/log/vps-integration/api.log'))
AUTH_TOKENS_PATH = Path(os.getenv('VPS_AUTH_PATH', '/etc/vps-integration/auth_tokens.json'))
COMMAND_WHITELIST_PATH = Path(os.getenv('VPS_WHITELIST_PATH', '/etc/vps-integration/command_whitelist.json'))

# Setup logging
LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_PATH),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('VPS_SECRET_KEY', secrets.token_hex(32))
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max request size

# Rate limiting
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["100 per hour", "20 per minute"],
    storage_uri="memory://"
)

# Security configuration
class SecurityConfig:
    JWT_ALGORITHM = 'HS256'
    TOKEN_EXPIRY_HOURS = 24
    MAX_COMMAND_LENGTH = 1000
    ALLOWED_COMMANDS = [
        'apt', 'yum', 'dnf', 'docker', 'systemctl', 'git',
        'npm', 'pip', 'python', 'node', 'ls', 'cat', 'grep',
        'ps', 'df', 'du', 'free', 'top', 'htop', 'netstat'
    ]
    BLOCKED_PATTERNS = [
        'rm -rf /', ';', '&&', '||', '`', '$(', '|',
        'shutdown', 'reboot', 'init', 'passwd', 'su ', 'sudo su'
    ]

# Utility functions
def load_config() -> Dict:
    """Load configuration from file."""
    if CONFIG_PATH.exists():
        with open(CONFIG_PATH, 'r') as f:
            return json.load(f)
    return {
        'host': '0.0.0.0',
        'port': 5000,
        'debug': False,
        'ssl_enabled': True,
        'ssl_cert': '/etc/vps-integration/ssl/cert.pem',
        'ssl_key': '/etc/vps-integration/ssl/key.pem'
    }

def load_auth_tokens() -> Dict:
    """Load authorized API tokens."""
    if AUTH_TOKENS_PATH.exists():
        with open(AUTH_TOKENS_PATH, 'r') as f:
            return json.load(f)
    return {}

def load_command_whitelist() -> List[str]:
    """Load command whitelist."""
    if COMMAND_WHITELIST_PATH.exists():
        with open(COMMAND_WHITELIST_PATH, 'r') as f:
            data = json.load(f)
            return data.get('commands', [])
    return []

def validate_command(command: str) -> Tuple[bool, str]:
    """Validate command for security."""
    # Check command length
    if len(command) > SecurityConfig.MAX_COMMAND_LENGTH:
        return False, "Command exceeds maximum length"
    
    # Check for blocked patterns
    for pattern in SecurityConfig.BLOCKED_PATTERNS:
        if pattern in command.lower():
            return False, f"Command contains blocked pattern: {pattern}"
    
    # Check if command starts with allowed command
    command_parts = command.strip().split()
    if not command_parts:
        return False, "Empty command"
    
    base_command = command_parts[0]
    
    # Check against whitelist
    whitelist = load_command_whitelist()
    if whitelist:
        if command not in whitelist:
            return False, "Command not in whitelist"
    else:
        # Use default allowed commands
        if base_command not in SecurityConfig.ALLOWED_COMMANDS:
            return False, f"Command '{base_command}' not allowed"
    
    return True, "Command validated"

def generate_jwt_token(client_id: str, permissions: List[str]) -> str:
    """Generate JWT token for authentication."""
    payload = {
        'client_id': client_id,
        'permissions': permissions,
        'exp': datetime.utcnow() + timedelta(hours=SecurityConfig.TOKEN_EXPIRY_HOURS),
        'iat': datetime.utcnow()
    }
    token = jwt.encode(payload, app.config['SECRET_KEY'], algorithm=SecurityConfig.JWT_ALGORITHM)
    return token

def verify_jwt_token(token: str) -> Optional[Dict]:
    """Verify JWT token."""
    try:
        payload = jwt.decode(token, app.config['SECRET_KEY'], algorithms=[SecurityConfig.JWT_ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        logger.warning("Token has expired")
        return None
    except jwt.InvalidTokenError:
        logger.warning("Invalid token")
        return None

def require_auth(f):
    """Decorator for authentication."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Get token from header
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            logger.warning(f"Unauthorized access attempt from {request.remote_addr}")
            return jsonify({'error': 'Authorization header required'}), 401
        
        # Extract token
        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != 'bearer':
            return jsonify({'error': 'Invalid authorization header format'}), 401
        
        token = parts[1]
        
        # Verify token
        payload = verify_jwt_token(token)
        if not payload:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        # Add payload to request context
        request.auth_payload = payload
        logger.info(f"Authenticated request from client: {payload.get('client_id')}")
        
        return f(*args, **kwargs)
    return decorated_function

def require_permission(permission: str):
    """Decorator to check specific permission."""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not hasattr(request, 'auth_payload'):
                return jsonify({'error': 'Not authenticated'}), 401
            
            permissions = request.auth_payload.get('permissions', [])
            if permission not in permissions and 'admin' not in permissions:
                logger.warning(f"Permission denied for {request.auth_payload.get('client_id')}")
                return jsonify({'error': f'Permission denied: {permission} required'}), 403
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator

# API Routes
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0'
    }), 200

@app.route('/api/v1/auth/token', methods=['POST'])
@limiter.limit("5 per minute")
def get_token():
    """Authenticate and get JWT token."""
    data = request.get_json()
    
    if not data or 'client_id' not in data or 'api_key' not in data:
        return jsonify({'error': 'client_id and api_key required'}), 400
    
    client_id = data['client_id']
    api_key = data['api_key']
    
    # Load and verify credentials
    auth_tokens = load_auth_tokens()
    
    if client_id not in auth_tokens:
        logger.warning(f"Invalid client_id: {client_id}")
        return jsonify({'error': 'Invalid credentials'}), 401
    
    stored_data = auth_tokens[client_id]
    stored_key_hash = stored_data.get('api_key_hash')
    
    # Verify API key
    key_hash = hashlib.sha256(api_key.encode()).hexdigest()
    if not hmac.compare_digest(key_hash, stored_key_hash):
        logger.warning(f"Invalid API key for client: {client_id}")
        return jsonify({'error': 'Invalid credentials'}), 401
    
    # Generate JWT token
    permissions = stored_data.get('permissions', ['read'])
    token = generate_jwt_token(client_id, permissions)
    
    logger.info(f"Token generated for client: {client_id}")
    
    return jsonify({
        'token': token,
        'expires_in': SecurityConfig.TOKEN_EXPIRY_HOURS * 3600,
        'token_type': 'Bearer'
    }), 200

@app.route('/api/v1/execute', methods=['POST'])
@limiter.limit("30 per minute")
@require_auth
@require_permission('execute')
def execute_command():
    """Execute a command on the VPS."""
    data = request.get_json()
    
    if not data or 'command' not in data:
        return jsonify({'error': 'command field required'}), 400
    
    command = data['command']
    working_dir = data.get('working_dir', '/tmp')
    timeout = min(data.get('timeout', 30), 300)  # Max 5 minutes
    
    # Validate command
    is_valid, message = validate_command(command)
    if not is_valid:
        logger.warning(f"Invalid command rejected: {command}")
        return jsonify({'error': message}), 400
    
    logger.info(f"Executing command: {command}")
    
    try:
        # Execute command
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=working_dir
        )
        
        response = {
            'success': result.returncode == 0,
            'return_code': result.returncode,
            'stdout': result.stdout,
            'stderr': result.stderr,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        logger.info(f"Command executed successfully: {command}")
        return jsonify(response), 200
        
    except subprocess.TimeoutExpired:
        logger.error(f"Command timeout: {command}")
        return jsonify({'error': 'Command execution timeout'}), 408
    
    except Exception as e:
        logger.error(f"Command execution error: {str(e)}")
        return jsonify({'error': f'Execution error: {str(e)}'}), 500

@app.route('/api/v1/install', methods=['POST'])
@limiter.limit("10 per hour")
@require_auth
@require_permission('install')
def install_package():
    """Install a package on the VPS."""
    data = request.get_json()
    
    if not data or 'package' not in data:
        return jsonify({'error': 'package field required'}), 400
    
    package = data['package']
    package_manager = data.get('package_manager', 'apt')
    
    # Validate package manager
    allowed_managers = ['apt', 'yum', 'dnf', 'pip', 'npm']
    if package_manager not in allowed_managers:
        return jsonify({'error': f'Unsupported package manager: {package_manager}'}), 400
    
    # Build install command
    if package_manager in ['apt', 'yum', 'dnf']:
        command = f"sudo {package_manager} install -y {package}"
    elif package_manager == 'pip':
        command = f"pip install {package}"
    elif package_manager == 'npm':
        command = f"npm install -g {package}"
    
    logger.info(f"Installing package: {package} with {package_manager}")
    
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=600  # 10 minutes for installations
        )
        
        response = {
            'success': result.returncode == 0,
            'return_code': result.returncode,
            'stdout': result.stdout,
            'stderr': result.stderr,
            'package': package,
            'package_manager': package_manager
        }
        
        return jsonify(response), 200
        
    except Exception as e:
        logger.error(f"Package installation error: {str(e)}")
        return jsonify({'error': f'Installation error: {str(e)}'}), 500

@app.route('/api/v1/status', methods=['GET'])
@require_auth
def get_vps_status():
    """Get VPS system status."""
    try:
        # Get system information
        commands = {
            'cpu': "top -bn1 | grep 'Cpu(s)' | awk '{print $2}'",
            'memory': "free -m | awk 'NR==2{printf \"%s/%s MB (%.2f%%)\", $3,$2,$3*100/$2 }'",
            'disk': "df -h / | awk 'NR==2{print $3\"/\"$2\" (\"$5\")"}'",
            'uptime': "uptime -p"
        }
        
        status = {}
        for key, cmd in commands.items():
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=5)
            status[key] = result.stdout.strip() if result.returncode == 0 else 'N/A'
        
        return jsonify({
            'status': status,
            'timestamp': datetime.utcnow().isoformat()
        }), 200
        
    except Exception as e:
        logger.error(f"Status check error: {str(e)}")
        return jsonify({'error': f'Status check failed: {str(e)}'}), 500

@app.route('/api/v1/files/read', methods=['POST'])
@limiter.limit("50 per minute")
@require_auth
@require_permission('read')
def read_file():
    """Read a file from the VPS."""
    data = request.get_json()
    
    if not data or 'path' not in data:
        return jsonify({'error': 'path field required'}), 400
    
    file_path = Path(data['path'])
    
    # Security check - prevent directory traversal
    if '..' in str(file_path):
        return jsonify({'error': 'Invalid path'}), 400
    
    try:
        if not file_path.exists():
            return jsonify({'error': 'File not found'}), 404
        
        if not file_path.is_file():
            return jsonify({'error': 'Path is not a file'}), 400
        
        # Read file content
        with open(file_path, 'r') as f:
            content = f.read()
        
        return jsonify({
            'path': str(file_path),
            'content': content,
            'size': file_path.stat().st_size
        }), 200
        
    except Exception as e:
        logger.error(f"File read error: {str(e)}")
        return jsonify({'error': f'Read error: {str(e)}'}), 500

@app.route('/api/v1/files/write', methods=['POST'])
@limiter.limit("20 per minute")
@require_auth
@require_permission('write')
def write_file():
    """Write a file to the VPS."""
    data = request.get_json()
    
    if not data or 'path' not in data or 'content' not in data:
        return jsonify({'error': 'path and content fields required'}), 400
    
    file_path = Path(data['path'])
    content = data['content']
    
    # Security check
    if '..' in str(file_path):
        return jsonify({'error': 'Invalid path'}), 400
    
    try:
        # Create parent directory if needed
        file_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Write file
        with open(file_path, 'w') as f:
            f.write(content)
        
        logger.info(f"File written: {file_path}")
        
        return jsonify({
            'success': True,
            'path': str(file_path),
            'size': file_path.stat().st_size
        }), 200
        
    except Exception as e:
        logger.error(f"File write error: {str(e)}")
        return jsonify({'error': f'Write error: {str(e)}'}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    config = load_config()
    
    logger.info("Starting VPS API Server...")
    logger.info(f"Config path: {CONFIG_PATH}")
    logger.info(f"Log path: {LOG_PATH}")
    
    if config.get('ssl_enabled'):
        ssl_context = (config['ssl_cert'], config['ssl_key'])
        app.run(
            host=config['host'],
            port=config['port'],
            debug=config['debug'],
            ssl_context=ssl_context
        )
    else:
        logger.warning("Running without SSL - not recommended for production!")
        app.run(
            host=config['host'],
            port=config['port'],
            debug=config['debug']
        )
