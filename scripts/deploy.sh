#!/bin/bash
# Deployment wrapper script for common operations

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

echo "=== Homelab Deployment Script ==="
echo

# Check if vault password exists
if [ ! -f "$HOME/.ansible-vault-pass" ]; then
    echo "❌ Vault password file not found: $HOME/.ansible-vault-pass"
    echo "   Run: ./scripts/init-vault.sh"
    exit 1
fi

# Show menu
echo "Select deployment option:"
echo "  1) Deploy everything to all machines"
echo "  2) Deploy to specific machine"
echo "  3) Deploy specific service"
echo "  4) Deploy Traefik only"
echo "  5) Deploy Beszel only"
echo "  6) Check mode (dry run)"
echo "  7) Custom command"
echo

read -p "Enter choice [1-7]: " choice

case $choice in
    1)
        echo "Deploying everything..."
        ansible-playbook playbooks/site.yml
        ;;
    2)
        echo
        read -p "Enter machine name (machine1, machine2, machine3): " machine
        echo "Deploying to $machine..."
        ansible-playbook playbooks/site.yml --limit "$machine"
        ;;
    3)
        echo
        read -p "Enter service tag (traefik, beszel): " service
        echo "Deploying $service..."
        ansible-playbook playbooks/site.yml --tags "$service"
        ;;
    4)
        echo "Deploying Traefik only..."
        ansible-playbook playbooks/deploy-traefik.yml
        ;;
    5)
        echo "Deploying Beszel only..."
        ansible-playbook playbooks/deploy-beszel.yml
        ;;
    6)
        echo "Running in check mode (no changes will be made)..."
        ansible-playbook playbooks/site.yml --check --diff
        ;;
    7)
        echo
        read -p "Enter custom ansible-playbook command: " custom
        eval "ansible-playbook $custom"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo
echo "✅ Deployment complete!"
