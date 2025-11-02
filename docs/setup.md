# Homelab Setup Guide

⚠️ **NOTE:** This project is currently under construction. This guide documents the intended deployment workflow once the build is complete.

## Prerequisites

- 3 machines running Ubuntu/Debian (orac, jarvis, seraph)
- SSH access to all machines with sudo privileges
- Machines accessible via Tailscale VPN
- Ansible installed on your control machine
- Domain name with Cloudflare DNS (for Traefik SSL certificates)

## Initial Setup

### 1. Install Ansible

On your control machine (where you'll run Ansible from):

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ansible

# macOS
brew install ansible

# Verify installation
ansible --version
```

### 2. Install Required Ansible Collections

```bash
ansible-galaxy collection install community.docker
ansible-galaxy collection install ansible.posix
```

### 3. Clone the Repository

```bash
cd ~/Projects
git clone https://github.com/danjam/homelab.git
cd homelab
```

### 4. Set Up Vault Password

```bash
# Generate a strong password and save to file
openssl rand -base64 32 > .ansible-vault-pass

# Set proper permissions
chmod 600 .ansible-vault-pass

# Keep a backup of this password in your password manager!
```

### 5. Generate Beszel Keys

```bash
# Run setup playbook to generate Beszel ED25519 keypair
ansible-playbook playbooks/setup-secrets.yml
```

This creates keys in `.secrets/` directory (git-ignored).

### 6. Configure Secrets

Edit the vault file and fill in your secrets:

```bash
ansible-vault edit inventory/group_vars/all/vault.yml
```

See [secrets.md](secrets.md) for detailed list of required secrets and how to obtain API credentials.

### 7. Test Connectivity

```bash
# Test SSH connection to all machines
ansible all -m ping

# Expected output:
# orac | SUCCESS => { ... }
# jarvis | SUCCESS => { ... }
# seraph | SUCCESS => { ... }
```

### 8. Deploy!

See [deployment.md](deployment.md) for deployment instructions.

## Machine Details

The inventory is pre-configured for three machines:

- **orac** (ansible_host: orac, ansible_user: danjam)
  - 19 services total (13 unique + 6 common)
  - NAS mounts from 192.168.1.60

- **jarvis** (ansible_host: jarvis, ansible_user: danjam)
  - 7 services total (1 unique + 6 common)

- **seraph** (ansible_host: seraph, ansible_user: danjam)
  - 11 services total (4 unique + 7 common)
  - Hosts Beszel hub

All machines are accessed via Tailscale VPN, so hostnames resolve automatically.
