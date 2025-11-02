# Common Role

Base system setup role for homelab infrastructure. This role provides foundational configuration that all machines need.

## Purpose

Prepares machines with:
- Essential system packages
- Base directory structure for homelab services
- Update/maintenance scripts

## What It Does

### 1. Package Installation
Installs common system packages needed across all machines:
- Development tools: curl, wget, git, vim
- System utilities: htop, tree, net-tools, dnsutils
- Data tools: jq, unzip
- Security: ca-certificates, gnupg

### 2. Directory Structure
Creates the base homelab directory structure:
```
/opt/homelab/
├── config/     # Service configurations
├── data/       # Service data
├── logs/       # Service logs
└── secrets/    # Docker secrets (mode 0700)
```

### 3. Update Scripts
Deploys maintenance scripts to `/usr/local/bin/`:

**update-docker.sh**
- Updates all Docker containers or a specific service
- Pulls latest images, recreates containers
- Cleans up old images

Usage:
```bash
# Update all services
sudo update-docker.sh

# Update specific service
sudo update-docker.sh traefik
```

**update-ubuntu.sh**
- Updates Ubuntu system packages
- Performs distribution upgrades
- Cleans up unused packages
- Checks if reboot required

Usage:
```bash
sudo update-ubuntu.sh
```

## Variables

### Required (from group_vars)
- `homelab_dir`: Base directory path (default: /opt/homelab)
- `default_username`: System user owning homelab files
- `hostname`: Machine hostname
- `domain`: Machine's full domain name

### Role Defaults (defaults/main.yml)
- `common_packages`: List of packages to install
- `deploy_update_scripts`: Whether to deploy update scripts (default: true)
- `update_scripts_dir`: Where to place scripts (default: /usr/local/bin)

## Dependencies

None - this is a foundational role.


## Tags

- `packages`: Package installation only
- `directories`: Directory structure creation only
- `secrets`: Secrets directory setup only
- `scripts`: Update scripts deployment only

## Example Usage

**In a playbook:**
```yaml
- hosts: homelab
  become: yes
  roles:
    - role: common
      tags: ['common', 'base']
```

**Deploy only packages:**
```bash
ansible-playbook playbooks/site.yml --tags packages
```

**Deploy only scripts:**
```bash
ansible-playbook playbooks/site.yml --tags scripts
```

**Deploy to specific machine:**
```bash
ansible-playbook playbooks/site.yml --limit orac --tags common
```

## Notes

- Run this role before any other service roles
- The secrets directory has restricted permissions (0700) for security
- Update scripts are templated with machine-specific information
- All directories are owned by the configured homelab user
