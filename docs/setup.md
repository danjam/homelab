# Homelab Setup Guide

## Prerequisites

- 3 machines running Ubuntu/Debian
- SSH access to all machines with sudo privileges
- Ansible installed on your control machine (laptop/desktop)
- Domain name with Cloudflare DNS (for Traefik SSL)

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
```

### 3. Clone the Repository

```bash
cd ~/Projects
git clone https://github.com/yourusername/homelab.git
cd homelab
```

### 4. Set Up Vault Password

```bash
# Copy the example file
cp .ansible-vault-pass.example ~/.ansible-vault-pass

# Generate a strong password
openssl rand -base64 32

# Edit the file and paste your password
nano ~/.ansible-vault-pass

# Set proper permissions
chmod 600 ~/.ansible-vault-pass
```

### 5. Configure Inventory

Edit `inventory/hosts.yml` with your actual machine details:

```yaml
all:
  children:
    homelab:
      hosts:
        machine1:
          ansible_host: 192.168.1.10  # Change to your IP
          ansible_user: youruser       # Change to your username
```

### 6. Update Variables

Edit machine-specific variables in:
- `host_vars/machine1/vars.yml`
- `host_vars/machine2/vars.yml`
- `host_vars/machine3/vars.yml`

Update values like:
- `domain` - Your actual domain
- Service paths (media_path, storage_path, etc.)
- Services to deploy on each machine

### 7. Configure Secrets

See [secrets.md](secrets.md) for detailed instructions on setting up encrypted secrets.

### 8. Test SSH Connectivity

```bash
# Test connection to all machines
ansible all -m ping

# Expected output: SUCCESS
```

### 9. Deploy!

See [deployment.md](deployment.md) for deployment instructions.
