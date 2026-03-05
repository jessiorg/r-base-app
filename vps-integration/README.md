# VPS Integration for Oracle VPS

## Overview

This VPS integration provides a secure API endpoint that allows Poke (via MCP - Model Context Protocol) to connect directly to an Oracle VPS for remote command execution, installations, and configurations.

## Features

✅ **Secure API Endpoint** - HTTPS with SSL/TLS encryption
✅ **JWT Authentication** - Token-based authentication with API keys
✅ **Permission System** - Granular permission control (read, execute, install, write, admin)
✅ **Rate Limiting** - Protection against abuse
✅ **Command Validation** - Whitelist and pattern-based security
✅ **Audit Logging** - Complete audit trail of all operations
✅ **Error Handling** - Comprehensive error handling and reporting
✅ **MCP Integration** - Ready for Poke MCP connection

## Architecture

```
┌─────────────┐          ┌──────────────────┐          ┌─────────────┐
│    Poke     │          │   VPS API        │          │  Oracle VPS │
│    (MCP)    │◄────────►│   Server         │◄────────►│  System     │
│             │  HTTPS   │  (Flask/Python)  │   Shell  │             │
└─────────────┘          └──────────────────┘          └─────────────┘
      │                         │                             │
      │                         │                             │
      ├─ JWT Token Auth         ├─ Rate Limiting              ├─ Command Exec
      ├─ API Requests           ├─ Permission Check           ├─ File Ops
      └─ MCP Protocol           └─ Audit Logging              └─ Package Install
```

## Installation

### Prerequisites

- Oracle VPS running Linux (Ubuntu 20.04+, CentOS 7+, or Oracle Linux)
- Python 3.8 or higher
- Root or sudo access
- Open port for API server (default: 5000)

### Quick Install

1. **Clone or copy files to your VPS:**

```bash
scp -r vps-integration/ user@your-vps-ip:/tmp/
ssh user@your-vps-ip
cd /tmp/vps-integration
```

2. **Run the setup script:**

```bash
sudo bash setup.sh
```

The setup script will:
- Install system dependencies
- Create Python virtual environment
- Generate SSL certificates
- Create configuration files
- Set up systemd service
- Configure firewall rules
- Start the API server

3. **Generate API credentials for Poke:**

```bash
sudo /opt/vps-integration/venv/bin/python /opt/vps-integration/auth_manager.py add-client poke read,execute,install,write,admin "Poke MCP Integration"
```

**IMPORTANT:** Save the generated API key securely!

## Configuration

### Main Configuration

**Location:** `/etc/vps-integration/config.json`

```json
{
    "host": "0.0.0.0",
    "port": 5000,
    "debug": false,
    "ssl_enabled": true,
    "ssl_cert": "/etc/vps-integration/ssl/cert.pem",
    "ssl_key": "/etc/vps-integration/ssl/key.pem"
}
```

### Command Whitelist

**Location:** `/etc/vps-integration/command_whitelist.json`

Define explicitly allowed commands:

```json
{
    "commands": [
        "ls -la",
        "docker ps",
        "systemctl status nginx",
        "git pull"
    ]
}
```

If empty, default allowed command prefixes are used.

### Authentication Tokens

**Location:** `/etc/vps-integration/auth_tokens.json`

Managed via `auth_manager.py` - **do not edit manually**.

## Usage

### Managing Clients

#### Add a new client:

```bash
sudo /opt/vps-integration/venv/bin/python /opt/vps-integration/auth_manager.py add-client <client_id> <permissions> "<description>"
```

Example:
```bash
sudo /opt/vps-integration/venv/bin/python /opt/vps-integration/auth_manager.py add-client poke read,execute,install,write,admin "Poke MCP Integration"
```

#### List all clients:

```bash
sudo /opt/vps-integration/venv/bin/python /opt/vps-integration/auth_manager.py list-clients
```

#### Rotate API key:

```bash
sudo /opt/vps-integration/venv/bin/python /opt/vps-integration/auth_manager.py rotate-key <client_id>
```

#### Update permissions:

```bash
sudo /opt/vps-integration/venv/bin/python /opt/vps-integration/auth_manager.py update-permissions <client_id> <new_permissions>
```

#### Remove a client:

```bash
sudo /opt/vps-integration/venv/bin/python /opt/vps-integration/auth_manager.py remove-client <client_id>
```

### Service Management

```bash
# Check status
sudo systemctl status vps-api

# Start service
sudo systemctl start vps-api

# Stop service
sudo systemctl stop vps-api

# Restart service
sudo systemctl restart vps-api

# View logs
sudo journalctl -u vps-api -f

# View application logs
sudo tail -f /var/log/vps-integration/api.log
```

## API Endpoints

### Authentication

#### Get JWT Token

```bash
POST /api/v1/auth/token
Content-Type: application/json

{
    "client_id": "poke",
    "api_key": "your-api-key-here"
}
```

Response:
```json
{
    "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "expires_in": 86400,
    "token_type": "Bearer"
}
```

### Execute Command

```bash
POST /api/v1/execute
Authorization: Bearer <token>
Content-Type: application/json

{
    "command": "ls -la /opt",
    "working_dir": "/opt",
    "timeout": 30
}
```

### Install Package

```bash
POST /api/v1/install
Authorization: Bearer <token>
Content-Type: application/json

{
    "package": "nginx",
    "package_manager": "apt"
}
```

### Get VPS Status

```bash
GET /api/v1/status
Authorization: Bearer <token>
```

### Read File

```bash
POST /api/v1/files/read
Authorization: Bearer <token>
Content-Type: application/json

{
    "path": "/etc/nginx/nginx.conf"
}
```

### Write File

```bash
POST /api/v1/files/write
Authorization: Bearer <token>
Content-Type: application/json

{
    "path": "/opt/myapp/config.txt",
    "content": "configuration content"
}
```

### Health Check

```bash
GET /health
```

## MCP Integration

### Connecting Poke to the VPS

To connect Poke via MCP to this VPS API server, you'll need to configure an MCP server that acts as a bridge.

#### 1. MCP Server Configuration

Create an MCP server configuration file for Poke:

**File: `mcp-vps-server.json`**

```json
{
  "mcpServers": {
    "oracle-vps": {
      "command": "node",
      "args": ["/path/to/mcp-vps-bridge.js"],
      "env": {
        "VPS_API_URL": "https://your-vps-ip:5000",
        "VPS_CLIENT_ID": "poke",
        "VPS_API_KEY": "your-generated-api-key",
        "VPS_SSL_VERIFY": "false"
      }
    }
  }
}
```

#### 2. MCP Bridge Script

Create an MCP bridge script that translates MCP requests to VPS API calls:

**File: `mcp-vps-bridge.js`**

```javascript
const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const axios = require('axios');
const https = require('https');

const VPS_API_URL = process.env.VPS_API_URL;
const VPS_CLIENT_ID = process.env.VPS_CLIENT_ID;
const VPS_API_KEY = process.env.VPS_API_KEY;
const VPS_SSL_VERIFY = process.env.VPS_SSL_VERIFY !== 'false';

let authToken = null;

// Create axios instance
const api = axios.create({
  baseURL: VPS_API_URL,
  httpsAgent: new https.Agent({
    rejectUnauthorized: VPS_SSL_VERIFY
  })
});

// Authenticate and get JWT token
async function authenticate() {
  try {
    const response = await api.post('/api/v1/auth/token', {
      client_id: VPS_CLIENT_ID,
      api_key: VPS_API_KEY
    });
    authToken = response.data.token;
    return true;
  } catch (error) {
    console.error('Authentication failed:', error.message);
    return false;
  }
}

// Execute command on VPS
async function executeCommand(command, workingDir = '/tmp', timeout = 30) {
  if (!authToken) {
    await authenticate();
  }
  
  try {
    const response = await api.post('/api/v1/execute', {
      command,
      working_dir: workingDir,
      timeout
    }, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });
    return response.data;
  } catch (error) {
    if (error.response?.status === 401) {
      // Token expired, re-authenticate
      await authenticate();
      return executeCommand(command, workingDir, timeout);
    }
    throw error;
  }
}

// Install package on VPS
async function installPackage(packageName, packageManager = 'apt') {
  if (!authToken) {
    await authenticate();
  }
  
  try {
    const response = await api.post('/api/v1/install', {
      package: packageName,
      package_manager: packageManager
    }, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });
    return response.data;
  } catch (error) {
    if (error.response?.status === 401) {
      await authenticate();
      return installPackage(packageName, packageManager);
    }
    throw error;
  }
}

// Get VPS status
async function getVPSStatus() {
  if (!authToken) {
    await authenticate();
  }
  
  try {
    const response = await api.get('/api/v1/status', {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });
    return response.data;
  } catch (error) {
    if (error.response?.status === 401) {
      await authenticate();
      return getVPSStatus();
    }
    throw error;
  }
}

// Read file from VPS
async function readFile(path) {
  if (!authToken) {
    await authenticate();
  }
  
  try {
    const response = await api.post('/api/v1/files/read', {
      path
    }, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });
    return response.data;
  } catch (error) {
    if (error.response?.status === 401) {
      await authenticate();
      return readFile(path);
    }
    throw error;
  }
}

// Write file to VPS
async function writeFile(path, content) {
  if (!authToken) {
    await authenticate();
  }
  
  try {
    const response = await api.post('/api/v1/files/write', {
      path,
      content
    }, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });
    return response.data;
  } catch (error) {
    if (error.response?.status === 401) {
      await authenticate();
      return writeFile(path, content);
    }
    throw error;
  }
}

// Create MCP server
const server = new Server({
  name: 'oracle-vps',
  version: '1.0.0',
}, {
  capabilities: {
    tools: {},
  },
});

// Define tools
server.setRequestHandler('tools/list', async () => {
  return {
    tools: [
      {
        name: 'vps_execute',
        description: 'Execute a command on the Oracle VPS',
        inputSchema: {
          type: 'object',
          properties: {
            command: {
              type: 'string',
              description: 'Command to execute'
            },
            working_dir: {
              type: 'string',
              description: 'Working directory (optional)',
              default: '/tmp'
            },
            timeout: {
              type: 'number',
              description: 'Timeout in seconds (optional)',
              default: 30
            }
          },
          required: ['command']
        }
      },
      {
        name: 'vps_install',
        description: 'Install a package on the Oracle VPS',
        inputSchema: {
          type: 'object',
          properties: {
            package: {
              type: 'string',
              description: 'Package name to install'
            },
            package_manager: {
              type: 'string',
              description: 'Package manager (apt, yum, dnf, pip, npm)',
              default: 'apt'
            }
          },
          required: ['package']
        }
      },
      {
        name: 'vps_status',
        description: 'Get Oracle VPS system status',
        inputSchema: {
          type: 'object',
          properties: {}
        }
      },
      {
        name: 'vps_read_file',
        description: 'Read a file from the Oracle VPS',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'File path to read'
            }
          },
          required: ['path']
        }
      },
      {
        name: 'vps_write_file',
        description: 'Write a file to the Oracle VPS',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'File path to write'
            },
            content: {
              type: 'string',
              description: 'File content'
            }
          },
          required: ['path', 'content']
        }
      }
    ]
  };
});

// Handle tool calls
server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params;
  
  try {
    switch (name) {
      case 'vps_execute':
        const execResult = await executeCommand(
          args.command,
          args.working_dir || '/tmp',
          args.timeout || 30
        );
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(execResult, null, 2)
            }
          ]
        };
      
      case 'vps_install':
        const installResult = await installPackage(
          args.package,
          args.package_manager || 'apt'
        );
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(installResult, null, 2)
            }
          ]
        };
      
      case 'vps_status':
        const statusResult = await getVPSStatus();
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(statusResult, null, 2)
            }
          ]
        };
      
      case 'vps_read_file':
        const readResult = await readFile(args.path);
        return {
          content: [
            {
              type: 'text',
              text: readResult.content
            }
          ]
        };
      
      case 'vps_write_file':
        const writeResult = await writeFile(args.path, args.content);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(writeResult, null, 2)
            }
          ]
        };
      
      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Error: ${error.message}`
        }
      ],
      isError: true
    };
  }
});

// Start server
async function main() {
  // Authenticate on startup
  const authenticated = await authenticate();
  if (!authenticated) {
    console.error('Failed to authenticate with VPS API');
    process.exit(1);
  }
  
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Oracle VPS MCP server running');
}

main().catch(console.error);
```

#### 3. Install Node.js Dependencies

```bash
npm install @modelcontextprotocol/sdk axios
```

#### 4. Configure Poke

Add the MCP server configuration to Poke's settings:

```bash
# Location depends on your Poke installation
~/.config/poke/mcp-servers.json
```

Or merge into existing configuration.

#### 5. Test the Connection

Ask Poke to:

```
"Check the status of the Oracle VPS"
"Execute 'df -h' on the VPS"
"Install nginx on the VPS"
```

## Security Best Practices

### 1. Use Strong SSL Certificates

Replace self-signed certificates with certificates from a trusted CA:

```bash
sudo certbot certonly --standalone -d your-vps-domain.com
sudo cp /etc/letsencrypt/live/your-vps-domain.com/fullchain.pem /etc/vps-integration/ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-vps-domain.com/privkey.pem /etc/vps-integration/ssl/key.pem
sudo systemctl restart vps-api
```

### 2. Restrict Network Access

Use firewall rules to limit access:

```bash
# Allow only specific IPs
sudo ufw deny 5000/tcp
sudo ufw allow from <poke-ip-address> to any port 5000
```

### 3. Enable Audit Logging

All operations are logged to `/var/log/vps-integration/api.log`

Monitor logs regularly:

```bash
sudo tail -f /var/log/vps-integration/api.log
```

### 4. Rotate API Keys Regularly

```bash
sudo /opt/vps-integration/venv/bin/python /opt/vps-integration/auth_manager.py rotate-key poke
```

### 5. Use Command Whitelist

For production, use explicit command whitelist:

```bash
sudo nano /etc/vps-integration/command_whitelist.json
```

### 6. Regular Security Updates

```bash
sudo apt update && sudo apt upgrade -y
```

### 7. Implement Reverse Proxy (Optional)

Use nginx as reverse proxy for additional security layer:

```nginx
server {
    listen 443 ssl http2;
    server_name vps-api.yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass https://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Troubleshooting

### Service Won't Start

```bash
# Check service status
sudo systemctl status vps-api

# Check logs
sudo journalctl -u vps-api -n 50

# Check application log
sudo cat /var/log/vps-integration/api.log
```

### Authentication Failures

```bash
# Verify credentials
sudo cat /etc/vps-integration/auth_tokens.json

# Re-generate credentials
sudo /opt/vps-integration/venv/bin/python /opt/vps-integration/auth_manager.py rotate-key poke
```

### SSL Certificate Issues

```bash
# Test certificate
openssl s_client -connect localhost:5000

# Re-generate self-signed certificate
sudo openssl req -x509 -newkey rsa:4096 -nodes \
    -out /etc/vps-integration/ssl/cert.pem \
    -keyout /etc/vps-integration/ssl/key.pem \
    -days 365
```

### Port Already in Use

```bash
# Find process using port
sudo lsof -i :5000

# Change port in config
sudo nano /etc/vps-integration/config.json
# Update port number and restart
sudo systemctl restart vps-api
```

### Permission Denied Errors

```bash
# Check file permissions
sudo ls -la /etc/vps-integration/

# Fix permissions
sudo chown -R vps-api:vps-api /etc/vps-integration/
sudo chown -R vps-api:vps-api /opt/vps-integration/
sudo chown -R vps-api:vps-api /var/log/vps-integration/
```

## Uninstallation

To completely remove the VPS integration:

```bash
# Stop service
sudo systemctl stop vps-api
sudo systemctl disable vps-api

# Remove files
sudo rm -rf /opt/vps-integration/
sudo rm -rf /etc/vps-integration/
sudo rm -rf /var/log/vps-integration/
sudo rm /etc/systemd/system/vps-api.service

# Remove user
sudo userdel vps-api

# Remove firewall rule
sudo ufw delete allow 5000/tcp

# Reload systemd
sudo systemctl daemon-reload
```

## Support and Contributing

For issues, questions, or contributions, please refer to the main repository documentation.

## License

This integration is provided as-is under the MIT License.

---

**Author:** Organiser  
**Date:** 2026-03-05  
**Version:** 1.0.0
