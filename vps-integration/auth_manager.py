#!/usr/bin/env python3
"""
Authentication Manager for VPS API

Utility to manage API clients, tokens, and permissions.

Author: Organiser
Date: 2026-03-05
"""

import os
import json
import hashlib
import secrets
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List

# Configuration
AUTH_TOKENS_PATH = Path(os.getenv('VPS_AUTH_PATH', '/etc/vps-integration/auth_tokens.json'))

class AuthManager:
    def __init__(self):
        self.tokens_path = AUTH_TOKENS_PATH
        self.tokens_path.parent.mkdir(parents=True, exist_ok=True)
        
    def load_tokens(self) -> Dict:
        """Load auth tokens from file."""
        if self.tokens_path.exists():
            with open(self.tokens_path, 'r') as f:
                return json.load(f)
        return {}
    
    def save_tokens(self, tokens: Dict):
        """Save auth tokens to file."""
        with open(self.tokens_path, 'w') as f:
            json.dump(tokens, f, indent=4)
        # Secure the file
        os.chmod(self.tokens_path, 0o600)
    
    def generate_api_key(self) -> str:
        """Generate a secure API key."""
        return secrets.token_urlsafe(32)
    
    def hash_api_key(self, api_key: str) -> str:
        """Hash an API key."""
        return hashlib.sha256(api_key.encode()).hexdigest()
    
    def add_client(self, client_id: str, permissions: List[str] = None, description: str = ""):
        """Add a new client."""
        if permissions is None:
            permissions = ['read', 'execute']
        
        tokens = self.load_tokens()
        
        if client_id in tokens:
            print(f"Error: Client '{client_id}' already exists")
            return False
        
        # Generate API key
        api_key = self.generate_api_key()
        api_key_hash = self.hash_api_key(api_key)
        
        # Add client
        tokens[client_id] = {
            'api_key_hash': api_key_hash,
            'permissions': permissions,
            'description': description or f"Client {client_id}",
            'created_at': datetime.utcnow().isoformat()
        }
        
        self.save_tokens(tokens)
        
        print(f"\n=== Client Added Successfully ===")
        print(f"Client ID: {client_id}")
        print(f"API Key: {api_key}")
        print(f"Permissions: {', '.join(permissions)}")
        print(f"\nIMPORTANT: Save the API key securely. It cannot be retrieved later.")
        print(f"\nTo authenticate, use:")
        print(f"  Client ID: {client_id}")
        print(f"  API Key: {api_key}")
        print()
        
        return True
    
    def remove_client(self, client_id: str):
        """Remove a client."""
        tokens = self.load_tokens()
        
        if client_id not in tokens:
            print(f"Error: Client '{client_id}' not found")
            return False
        
        del tokens[client_id]
        self.save_tokens(tokens)
        
        print(f"Client '{client_id}' removed successfully")
        return True
    
    def list_clients(self):
        """List all clients."""
        tokens = self.load_tokens()
        
        if not tokens:
            print("No clients found")
            return
        
        print(f"\n{'='*80}")
        print(f"{'Client ID':<20} {'Permissions':<30} {'Created At':<20}")
        print(f"{'='*80}")
        
        for client_id, data in tokens.items():
            permissions = ', '.join(data.get('permissions', []))
            created_at = data.get('created_at', 'N/A')[:19]
            print(f"{client_id:<20} {permissions:<30} {created_at:<20}")
        
        print(f"{'='*80}\n")
    
    def update_permissions(self, client_id: str, permissions: List[str]):
        """Update client permissions."""
        tokens = self.load_tokens()
        
        if client_id not in tokens:
            print(f"Error: Client '{client_id}' not found")
            return False
        
        tokens[client_id]['permissions'] = permissions
        tokens[client_id]['updated_at'] = datetime.utcnow().isoformat()
        
        self.save_tokens(tokens)
        
        print(f"Permissions updated for client '{client_id}'")
        print(f"New permissions: {', '.join(permissions)}")
        return True
    
    def rotate_key(self, client_id: str):
        """Rotate API key for a client."""
        tokens = self.load_tokens()
        
        if client_id not in tokens:
            print(f"Error: Client '{client_id}' not found")
            return False
        
        # Generate new API key
        api_key = self.generate_api_key()
        api_key_hash = self.hash_api_key(api_key)
        
        # Update token
        tokens[client_id]['api_key_hash'] = api_key_hash
        tokens[client_id]['updated_at'] = datetime.utcnow().isoformat()
        
        self.save_tokens(tokens)
        
        print(f"\n=== API Key Rotated ===")
        print(f"Client ID: {client_id}")
        print(f"New API Key: {api_key}")
        print(f"\nIMPORTANT: Update your client with the new API key.")
        print()
        
        return True

def print_usage():
    """Print usage information."""
    print("""
VPS API Authentication Manager

Usage:
    auth_manager.py <command> [arguments]

Commands:
    add-client <client_id> [permissions] [description]
        Add a new client with API credentials
        Permissions: comma-separated list (read,execute,install,write,admin)
        Example: auth_manager.py add-client poke read,execute,install "Poke MCP client"
    
    remove-client <client_id>
        Remove a client
        Example: auth_manager.py remove-client poke
    
    list-clients
        List all clients
        Example: auth_manager.py list-clients
    
    update-permissions <client_id> <permissions>
        Update client permissions
        Example: auth_manager.py update-permissions poke read,execute,install,admin
    
    rotate-key <client_id>
        Rotate API key for a client
        Example: auth_manager.py rotate-key poke

Permission Types:
    read      - Read files and get status
    execute   - Execute commands
    install   - Install packages
    write     - Write files
    admin     - Full administrative access

Examples:
    # Add Poke client with full permissions
    auth_manager.py add-client poke read,execute,install,write,admin "Poke MCP Integration"
    
    # Add monitoring client with limited permissions
    auth_manager.py add-client monitor read "Monitoring service"
    
    # List all clients
    auth_manager.py list-clients
    
    # Rotate API key
    auth_manager.py rotate-key poke
    """)

def main():
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)
    
    command = sys.argv[1].lower()
    manager = AuthManager()
    
    if command == 'add-client':
        if len(sys.argv) < 3:
            print("Error: Client ID required")
            print("Usage: auth_manager.py add-client <client_id> [permissions] [description]")
            sys.exit(1)
        
        client_id = sys.argv[2]
        permissions = sys.argv[3].split(',') if len(sys.argv) > 3 else ['read', 'execute']
        description = sys.argv[4] if len(sys.argv) > 4 else ""
        
        manager.add_client(client_id, permissions, description)
    
    elif command == 'remove-client':
        if len(sys.argv) < 3:
            print("Error: Client ID required")
            print("Usage: auth_manager.py remove-client <client_id>")
            sys.exit(1)
        
        client_id = sys.argv[2]
        manager.remove_client(client_id)
    
    elif command == 'list-clients':
        manager.list_clients()
    
    elif command == 'update-permissions':
        if len(sys.argv) < 4:
            print("Error: Client ID and permissions required")
            print("Usage: auth_manager.py update-permissions <client_id> <permissions>")
            sys.exit(1)
        
        client_id = sys.argv[2]
        permissions = sys.argv[3].split(',')
        manager.update_permissions(client_id, permissions)
    
    elif command == 'rotate-key':
        if len(sys.argv) < 3:
            print("Error: Client ID required")
            print("Usage: auth_manager.py rotate-key <client_id>")
            sys.exit(1)
        
        client_id = sys.argv[2]
        manager.rotate_key(client_id)
    
    else:
        print(f"Error: Unknown command '{command}'")
        print_usage()
        sys.exit(1)

if __name__ == '__main__':
    main()
