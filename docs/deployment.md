# Deployment Guide

## Quick Start

Deploy everything to all machines:

```bash
ansible-playbook playbooks/site.yml
```

## Deployment Options

### Deploy to Specific Machine

```bash
# Deploy only to machine1
ansible-playbook playbooks/site.yml --limit machine1

# Deploy to multiple specific machines
ansible-playbook playbooks/site.yml --limit machine1,machine2
```

### Deploy Specific Services

```bash
# Deploy only Traefik
ansible-playbook playbooks/site.yml --tags traefik

# Deploy only Beszel
ansible-playbook playbooks/site.yml --tags beszel

# Deploy multiple services
ansible-playbook playbooks/site.yml --tags traefik,beszel
```

### Service-Specific Playbooks

```bash
# Traefik only
ansible-playbook playbooks/deploy-traefik.yml

# Beszel only
ansible-playbook playbooks/deploy-beszel.yml
```

### Combine Limits and Tags

```bash
# Deploy Traefik only to machine1
ansible-playbook playbooks/site.yml --limit machine1 --tags traefik
```

## Dry Run (Check Mode)


See what would change without actually making changes:

```bash
ansible-playbook playbooks/site.yml --check --diff
```

## Common Workflows

### Initial Deployment

```bash
# 1. Test connectivity
ansible all -m ping

# 2. Deploy Docker and common setup
ansible-playbook playbooks/site.yml --tags docker,common

# 3. Deploy services
ansible-playbook playbooks/site.yml --tags traefik,beszel

# 4. Deploy machine-specific services (example)
ansible-playbook playbooks/site.yml --tags navidrome --limit orac
```

### Update Configuration

After changing variables or templates:

```bash
# Update specific service
ansible-playbook playbooks/site.yml --tags traefik

# Will only update changed files and restart if needed
```

### Update Docker Images

```bash
# Pull latest images and recreate containers
ansible-playbook playbooks/site.yml
```

### Troubleshooting

```bash
# Verbose output
ansible-playbook playbooks/site.yml -v

# Very verbose (connection debugging)
ansible-playbook playbooks/site.yml -vvv

# Skip specific machines if one is down
ansible-playbook playbooks/site.yml --limit '!machine2'
```

## Post-Deployment

After successful deployment, verify services:

```bash
# Check if services are running on each machine
ansible all -a "docker ps"

# Check Traefik dashboard (if enabled)
# https://traefik.yourdomain.com

# Check Beszel monitoring
# https://beszel.yourdomain.com
```
