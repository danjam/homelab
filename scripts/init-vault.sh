#!/bin/bash
# Initialize ansible-vault password file

set -e

VAULT_PASS_FILE="$HOME/.ansible-vault-pass"

echo "=== Ansible Vault Password Initialization ==="
echo

# Check if vault password already exists
if [ -f "$VAULT_PASS_FILE" ]; then
    echo "⚠️  Vault password file already exists: $VAULT_PASS_FILE"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Generate a strong password
echo "Generating a strong password..."
GENERATED_PASSWORD=$(openssl rand -base64 32)

echo
echo "Your generated vault password is:"
echo "================================="
echo "$GENERATED_PASSWORD"
echo "================================="
echo
echo "⚠️  IMPORTANT: Save this password in a secure location!"
echo "   - Password manager (recommended)"
echo "   - Secure backup"
echo
read -p "Press Enter to continue..."

# Write password to file
echo "$GENERATED_PASSWORD" > "$VAULT_PASS_FILE"

# Set proper permissions
chmod 600 "$VAULT_PASS_FILE"

echo
echo "✅ Vault password file created: $VAULT_PASS_FILE"
echo "✅ Permissions set to 600 (owner read/write only)"
echo
echo "Next steps:"
echo "1. Edit vault files with your actual secrets"
echo "2. Run: ansible-vault encrypt inventory/group_vars/all/vault.yml"
echo "3. Encrypt all host_vars vault files"
echo
