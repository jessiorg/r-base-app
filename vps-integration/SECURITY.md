# Security Guidelines for VPS Integration

## Overview

This document outlines security best practices and guidelines for deploying and maintaining the VPS Integration API server.

## Security Features

### 1. Authentication and Authorization

- **JWT Token-based Authentication**: All API requests (except health check and token generation) require valid JWT tokens
- **API Key Hashing**: API keys are stored as SHA-256 hashes
- **Permission-based Access Control**: Granular permissions (read, execute, install, write, admin)
- **Token Expiration**: JWT tokens expire after 24 hours (configurable)
- **Secure Token Generation**: Uses cryptographically secure random generators

### 2. Transport Security

- **HTTPS Only**: All communications encrypted with TLS/SSL
- **Certificate Validation**: Support for both self-signed and CA-issued certificates
- **Minimum TLS Version**: TLS 1.2 or higher recommended

### 3. Command Execution Security

- **Command Whitelist**: Explicit whitelist of allowed commands
- **Pattern Blocking**: Blocks dangerous patterns (e.g., `rm -rf /`, shell injection)
- **Command Length Limits**: Maximum command length enforced
- **Timeout Protection**: Commands automatically killed after timeout
- **Working Directory Restrictions**: Prevents directory traversal

### 4. Rate Limiting

- **Global Rate Limits**: 100 requests per hour per IP
- **Endpoint-specific Limits**: Stricter limits on sensitive operations
- **Authentication Attempts**: Limited to 5 per minute

### 5. Audit and Logging

- **Comprehensive Logging**: All operations logged with timestamps
- **Authentication Logging**: All auth attempts (success and failure) logged
- **Command Logging**: All executed commands logged
- **IP Address Logging**: Source IP addresses tracked
- **Log Rotation**: Automatic log rotation to prevent disk filling

### 6. File Operations Security

- **Path Validation**: Prevents directory traversal attacks
- **Size Limits**: Maximum file size limits enforced
- **Permission Checks**: File operations respect system permissions

## Deployment Security Checklist

### Pre-Deployment

- [ ] Generate strong SSL certificates (not self-signed for production)
- [ ] Change default ports if possible
- [ ] Configure firewall rules to restrict access
- [ ] Review and customize command whitelist
- [ ] Set up secure API key generation
- [ ] Review and adjust rate limits for your use case
- [ ] Configure log rotation
- [ ] Set up monitoring and alerting

### During Deployment

- [ ] Run as dedicated non-root user (vps-api)
- [ ] Set correct file permissions (600 for sensitive files)
- [ ] Enable SSL/TLS
- [ ] Configure proper log file locations
- [ ] Set up systemd service for auto-restart
- [ ] Test all security features

### Post-Deployment

- [ ] Monitor logs regularly
- [ ] Rotate API keys periodically
- [ ] Update SSL certificates before expiration
- [ ] Keep system and dependencies updated
- [ ] Review and update command whitelist as needed
- [ ] Conduct security audits periodically

## Security Configuration

### 1. Strong SSL Certificates

**Self-signed (Development Only):**

```bash
openssl req -x509 -newkey rsa:4096 -nodes \
  -out /etc/vps-integration/ssl/cert.pem \
  -keyout /etc/vps-integration/ssl/key.pem \
  -days 365 \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=vps-api.local"
```

**Let's Encrypt (Production):**

```bash
sudo certbot certonly --standalone -d your-domain.com
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /etc/vps-integration/ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem /etc/vps-integration/ssl/key.pem
sudo systemctl restart vps-api
```

### 2. Firewall Configuration

**UFW (Ubuntu/Debian):**

```bash
# Default deny
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow 22/tcp

# Allow VPS API only from specific IPs
sudo ufw allow from <trusted-ip> to any port 5000

# Enable firewall
sudo ufw enable
```

**FirewallD (CentOS/RHEL):**

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="<trusted-ip>" port protocol="tcp" port="5000" accept'
sudo firewall-cmd --reload
```

### 3. Command Whitelist Configuration

**Restrictive (Recommended for Production):**

```json
{
  "commands": [
    "docker ps",
    "docker ps -a",
    "docker images",
    "docker logs",
    "systemctl status nginx",
    "systemctl status docker",
    "git status",
    "git pull",
    "ls -la",
    "pwd",
    "df -h",
    "free -m"
  ]
}
```

**Permissive (Development Only):**

```json
{
  "commands": []
}
```

### 4. Permission Levels

**Read-Only Client:**
```bash
sudo /opt/vps-integration/venv/bin/python /opt/vps-integration/auth_manager.py add-client monitor read "Monitoring only"
```

**Standard Client:**
```bash
sudo /opt/vps-integration/venv/bin/python /opt/vps-integration/auth_manager.py add-client standard read,execute "Standard operations"
```

**Full Access Client:**
```bash
sudo /opt/vps-integration/venv/bin/python /opt/vps-integration/auth_manager.py add-client admin read,execute,install,write,admin "Full access"
```

## Security Incident Response

### Detecting Security Issues

**Monitor for suspicious activity:**

```bash
# Watch authentication failures
sudo grep "Invalid" /var/log/vps-integration/api.log

# Watch for blocked commands
sudo grep "Command contains blocked pattern" /var/log/vps-integration/api.log

# Watch for rate limit violations
sudo grep "rate limit exceeded" /var/log/vps-integration/api.log

# Watch for unauthorized access attempts
sudo grep "Unauthorized" /var/log/vps-integration/api.log
```

### Incident Response Steps

1. **Identify the Issue**
   - Check logs for anomalies
   - Identify affected systems
   - Determine attack vector

2. **Contain the Threat**
   ```bash
   # Stop the service immediately
   sudo systemctl stop vps-api
   
   # Block suspicious IPs
   sudo ufw deny from <suspicious-ip>
   ```

3. **Eradicate the Threat**
   ```bash
   # Rotate all API keys
   sudo /opt/vps-integration/venv/bin/python /opt/vps-integration/auth_manager.py list-clients
   # Rotate each client key
   sudo /opt/vps-integration/venv/bin/python /opt/vps-integration/auth_manager.py rotate-key <client_id>
   
   # Update SSL certificates
   # Generate new certificates
   ```

4. **Recover**
   - Review and update security configurations
   - Restart service with enhanced security
   - Monitor closely for 24-48 hours

5. **Post-Incident**
   - Document the incident
   - Update security procedures
   - Implement additional controls if needed

## Security Hardening

### System-Level Hardening

```bash
# Disable root login
sudo passwd -l root

# Enable automatic security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Configure fail2ban
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Harden SSH
sudo nano /etc/ssh/sshd_config
# Set: PermitRootLogin no
# Set: PasswordAuthentication no
# Set: PubkeyAuthentication yes
sudo systemctl restart sshd
```

### Application-Level Hardening

1. **Implement IP Whitelisting**

   Edit `/opt/vps-integration/vps_api_server.py` to add IP filtering:
   
   ```python
   ALLOWED_IPS = ['192.168.1.100', '10.0.0.50']
   
   @app.before_request
   def limit_remote_addr():
       if request.remote_addr not in ALLOWED_IPS:
           abort(403)
   ```

2. **Enable Request Signing**

   Add HMAC signature verification for additional security.

3. **Implement Two-Factor Authentication**

   Require time-based OTP in addition to API keys.

## Vulnerability Management

### Regular Security Updates

```bash
# System updates
sudo apt update && sudo apt upgrade -y

# Python dependencies
source /opt/vps-integration/venv/bin/activate
pip list --outdated
pip install --upgrade <package>

# Check for security advisories
pip install safety
safety check
```

### Security Scanning

```bash
# Port scanning
nmap -sV localhost

# Vulnerability scanning
sudo apt install lynis
sudo lynis audit system

# SSL/TLS testing
openssl s_client -connect localhost:5000 -tls1_2
```

## Security Contacts

For security issues or vulnerabilities:

1. **DO NOT** create public GitHub issues
2. Contact the security team directly
3. Provide detailed information about the vulnerability
4. Allow reasonable time for patch development

## Compliance Considerations

### Data Protection

- Logs may contain sensitive information - protect accordingly
- Ensure compliance with data protection regulations (GDPR, etc.)
- Implement data retention policies
- Consider encryption at rest for sensitive data

### Audit Requirements

- Maintain audit logs for required retention period
- Ensure log integrity (consider log signing)
- Regular audit log reviews
- Automated alerting for security events

## Security Updates

This security guide will be updated as new threats emerge and security practices evolve. Check regularly for updates.

**Last Updated:** 2026-03-05  
**Version:** 1.0.0
