# Deployment Guide

⚠️ **NOTE:** This project is currently under construction. The main deployment playbook (`site.yml`) has not been created yet. This guide documents the intended deployment workflow once the build is complete.

## Quick Start (When Available)

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
ansible-playbook playbooks/site.yml --tags traefik,dozzle,whatsupdocker

# Deploy all core infrastructure
ansible-playbook playbooks/site.yml --tags docker,common,nas

# Deploy all core services
ansible-playbook playbooks/site.yml --tags docker-socket-proxy,traefik,beszel,samba
```

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
# 1. Test connectivity
ansible all -m ping

# 2. Deploy core infrastructure (in order)
ansible-playbook playbooks/site.yml --tags common
ansible-playbook playbooks/site.yml --tags docker
ansible-playbook playbooks/site.yml --tags nas  # orac only

# 3. Deploy core services (in order - dependencies matter)
ansible-playbook playbooks/site.yml --tags docker-socket-proxy
ansible-playbook playbooks/site.yml --tags traefik
ansible-playbook playbooks/site.yml --tags beszel  # seraph only
ansible-playbook playbooks/site.yml --tags beszel-agent
ansible-playbook playbooks/site.yml --tags samba

# 4. Deploy common application services
ansible-playbook playbooks/site.yml --tags dozzle,whatsupdocker

# 5. Deploy machine-specific services (when roles are complete)
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

Services have dependencies and should be deployed in this order:

1. **Infrastructure:** common → docker → nas_mounts
2. **Proxy:** docker_socket_proxy → traefik
3. **Monitoring:** beszel (hub on seraph) → beszel_agent (all)
4. **Services:** samba, dozzle, whatsupdocker, then application-specific

The main playbook (`site.yml`) will handle this ordering automatically when complete.
