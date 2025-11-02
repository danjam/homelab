#!/bin/bash
# Encrypt all vault files with ansible-vault

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

echo "=== Ansible Vault Encryption Helper ==="
echo

# Check if vault password file exists
if [ ! -f "$HOME/.ansible-vault-pass" ]; then
    echo "❌ Vault password file not found: $HOME/.ansible-vault-pass"
    echo "   Run: ./scripts/init-vault.sh"
    exit 1
fi

# Find all vault files
VAULT_FILES=(
    "inventory/group_vars/all/vault.yml"
    "host_vars/machine1/vault.yml"
    "host_vars/machine2/vault.yml"
    "host_vars/machine3/vault.yml"
)

echo "Found vault files to encrypt:"
for file in "${VAULT_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  - $file"
    fi
done
echo

read -p "Continue with encryption? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo

# Encrypt each file
for file in "${VAULT_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "⚠️  Skipping (not found): $file"
        continue
    fi
    
    # Check if already encrypted
    if head -1 "$file" | grep -q "ANSIBLE_VAULT"; then
        echo "✅ Already encrypted: $file"
    else
        echo "🔒 Encrypting: $file"
        ansible-vault encrypt "$file"
        echo "✅ Encrypted: $file"
    fi
done

echo
echo "✅ Encryption complete!"
echo
echo "Verify encrypted files:"
echo "  ansible-vault view inventory/group_vars/all/vault.yml"
echo
