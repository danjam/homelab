# Deployment Guide

This guide documents deployment workflows for the homelab infrastructure using Ansible playbooks.

For comprehensive playbook documentation including all tags and usage patterns, see [playbooks/README.md](../playbooks/README.md).

## Quick Start

Deploy everything to all machines:

```bash
ansible-playbook playbooks/site.yml
```

## Deployment Options

### Deploy to Specific Machine

```bash
# Deploy only to orac
ansible-playbook playbooks/site.yml --limit orac

# Deploy to multiple specific machines
ansible-playbook playbooks/site.yml --limit orac,jarvis
```

### Deploy Specific Services

```bash
# Deploy only Traefik
ansible-playbook playbooks/site.yml --tags traefik

# Deploy only dozzle
ansible-playbook playbooks/site.yml --tags dozzle

# Deploy multiple services
ansible-playbook playbooks/site.yml --tags "traefik,dozzle,whatsupdocker"

# Deploy all infrastructure layer
ansible-playbook playbooks/site.yml --tags infrastructure

# Deploy all core services
ansible-playbook playbooks/site.yml --tags core-services

# Deploy all applications
ansible-playbook playbooks/site.yml --tags apps

# Deploy all monitoring services
ansible-playbook playbooks/site.yml --tags monitoring

# Deploy all storage services
ansible-playbook playbooks/site.yml --tags storage
```

See [playbooks/README.md](../playbooks/README.md) for complete tag reference.

### Combine Limits and Tags

```bash
# Deploy Traefik only to orac
ansible-playbook playbooks/site.yml --limit orac --tags traefik

# Deploy core services only to jarvis
ansible-playbook playbooks/site.yml --limit jarvis --tags traefik,dozzle,whatsupdocker
```

## Dry Run (Check Mode)


See what would change without actually making changes:

```bash
ansible-playbook playbooks/site.yml --check --diff
```

## Common Workflows

### Initial Deployment

```bash
# 1. Generate secrets (if not done yet)
ansible-playbook playbooks/setup-secrets.yml

# 2. Fill vault with secrets
ansible-vault edit inventory/group_vars/all/vault.yml

# 3. Test connectivity
ansible all -m ping

# 4. Deploy everything (recommended for first deployment)
ansible-playbook playbooks/site.yml

# OR deploy in phases:

# 5a. Deploy infrastructure layer (tailscale, common, docker, nas_mounts)
ansible-playbook playbooks/site.yml --tags infrastructure

# 5b. Deploy core services (docker_socket_proxy, traefik, beszel, samba)
ansible-playbook playbooks/site.yml --tags core-services

# 5c. Deploy applications (dozzle, whatsupdocker, beszel_agent)
ansible-playbook playbooks/site.yml --tags apps

# 6. Verify deployment
ansible-playbook playbooks/verify.yml
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
ansible-playbook playbooks/site.yml --limit '!jarvis'

# List all available tags
ansible-playbook playbooks/site.yml --list-tags

# List all available tasks
ansible-playbook playbooks/site.yml --list-tasks
```

## Post-Deployment

After successful deployment, verify services:

```bash
# Check if services are running on each machine
ansible all -a "docker ps"

# Check Docker networks exist
ansible all -a "docker network ls"

# Check specific service logs
ansible all -a "docker logs traefik" --limit orac
```

## Service URLs

After deployment, services will be accessible at:

**Common (all machines):**
- `https://traefik.{hostname}.dannyjames.net` - Traefik dashboard
- `https://dozzle.{hostname}.dannyjames.net` - Log viewer
- `https://wud.{hostname}.dannyjames.net` - Update checker

**Monitoring:**
- `https://beszel.dannyjames.net` - Beszel hub (seraph)

**Machine-specific:** See individual service roles for URLs.

## Deployment Order

Services have dependencies and are deployed in three phases:

**Phase 1: Foundation (Sequential)**
1. tailscale → common → docker → nas_mounts (if enabled)

**Phase 2: Infrastructure Services (Parallel)**
2. docker_socket_proxy, dozzle, whatsupdocker

**Phase 3: Dependent Services (Sequential)**
3. traefik → beszel (hub on seraph) → beszel_agent → samba

The main playbook (`site.yml`) handles this ordering automatically. See [playbooks/README.md](../playbooks/README.md) for detailed execution order and tag reference.
