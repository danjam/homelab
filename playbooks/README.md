# Homelab Playbooks

This directory contains Ansible playbooks for deploying and managing the homelab infrastructure.

## Playbook Overview

| Playbook | Purpose | When to Use |
|----------|---------|-------------|
| `site.yml` | Deploy complete infrastructure | Initial setup, full redeployment |
| `deploy-core.yml` | Deploy only core services | Update core infrastructure services |
| `verify.yml` | Health checks and verification | After deployment, troubleshooting |
| `stop-all.yml` | Stop all services | Maintenance, system updates |
| `setup-secrets.yml` | Generate secrets | Before first deployment |

---

## Main Playbook: site.yml

**Purpose:** Deploy the complete homelab infrastructure to all machines.

### Execution Order

Roles are executed in strict dependency order:

**Phase 1: Foundation** (Sequential)
1. `tailscale` - VPN networking layer
2. `common` - System setup and packages
3. `docker` - Container runtime and networks

**Phase 2: Infrastructure Services** (Parallel)
4. `nas_mounts` - NAS storage (conditional)
5. `docker_socket_proxy` - Secure Docker API
6. `dozzle` - Log viewer
7. `whatsupdocker` - Update checker

**Phase 3: Dependent Services** (Sequential)
8. `traefik` - Reverse proxy (requires docker_socket_proxy)
9. `beszel` - Monitoring hub (seraph only)
10. `beszel_agent` - Monitoring agents
11. `samba` - File sharing

### Usage Examples

```bash
# Deploy everything to all machines
ansible-playbook playbooks/site.yml

# Deploy to specific machine
ansible-playbook playbooks/site.yml --limit orac
ansible-playbook playbooks/site.yml --limit jarvis
ansible-playbook playbooks/site.yml --limit seraph

# Dry run (see what would change)
ansible-playbook playbooks/site.yml --check --diff

# Dry run on specific machine
ansible-playbook playbooks/site.yml --limit jarvis --check --diff

# Deploy specific service
ansible-playbook playbooks/site.yml --tags traefik

# Deploy multiple services
ansible-playbook playbooks/site.yml --tags "traefik,beszel"

# Deploy infrastructure layer only
ansible-playbook playbooks/site.yml --tags infrastructure

# Deploy core services only
ansible-playbook playbooks/site.yml --tags core-services

# Deploy applications only
ansible-playbook playbooks/site.yml --tags apps

# Deploy all monitoring services
ansible-playbook playbooks/site.yml --tags monitoring

# Deploy all storage services
ansible-playbook playbooks/site.yml --tags storage
```

---

## Tag Reference

### Layer Tags (by deployment phase)

| Tag | Includes | Description |
|-----|----------|-------------|
| `infrastructure` | tailscale, common, docker, nas_mounts | Foundation layer |
| `core-services` | docker_socket_proxy, traefik, beszel, samba | Core infrastructure services |
| `apps` | dozzle, whatsupdocker, beszel_agent | Application services |

### Function Tags (by purpose)

| Tag | Includes | Description |
|-----|----------|-------------|
| `base-os` | common | System setup |
| `network` | tailscale | VPN networking |
| `docker-engine` | docker | Container runtime |
| `storage` | nas_mounts, samba | Storage services |
| `docker-infra` | docker_socket_proxy, traefik | Docker infrastructure |
| `monitoring` | beszel, beszel_agent, dozzle, whatsupdocker | Monitoring stack |

### Individual Service Tags

Use the service name as tag:
- `tailscale`
- `common`
- `docker`
- `nas-mounts`
- `docker-socket-proxy`
- `traefik`
- `beszel`
- `beszel-agent`
- `samba`
- `dozzle`
- `whatsupdocker`

---

## Helper Playbook: deploy-core.yml

**Purpose:** Deploy only the core infrastructure services (faster than full deployment).

**Services included:**
- docker_socket_proxy
- traefik
- beszel (hub)
- beszel_agent

### Usage Examples

```bash
# Deploy core services to all machines
ansible-playbook playbooks/deploy-core.yml

# Deploy to specific machine
ansible-playbook playbooks/deploy-core.yml --limit orac

# Deploy only Traefik
ansible-playbook playbooks/deploy-core.yml --tags traefik

# Dry run
ansible-playbook playbooks/deploy-core.yml --check --diff
```

---

## Helper Playbook: verify.yml

**Purpose:** Verify infrastructure health and status after deployment.

**Checks performed:**
- Docker service status
- External networks exist (homelab, monitoring)
- Tailscale VPN connection
- Running containers and their status
- NAS mounts (on applicable machines)
- Unhealthy or stopped containers
- Disk space on /opt/homelab

### Usage Examples

```bash
# Verify all machines
ansible-playbook playbooks/verify.yml

# Verify specific machine
ansible-playbook playbooks/verify.yml --limit orac

# Quick check (skip detailed inspection)
ansible-playbook playbooks/verify.yml --tags quick

# Check only storage
ansible-playbook playbooks/verify.yml --tags storage

# Check only Tailscale
ansible-playbook playbooks/verify.yml --tags tailscale
```

### Available Tags
- `quick` - Fast basic checks
- `networks` - Network verification
- `tailscale` - VPN status
- `storage` - NAS mounts
- `containers` - Container status
- `health` - Health checks
- `system` - System resources

---

## Helper Playbook: stop-all.yml

**Purpose:** Stop all Docker Compose services for maintenance.

**⚠️ WARNING:** This stops ALL services, making them inaccessible until restarted.

### Usage Examples

```bash
# Stop all services on all machines
ansible-playbook playbooks/stop-all.yml

# Stop services on specific machine
ansible-playbook playbooks/stop-all.yml --limit orac

# Dry run (see what would be stopped)
ansible-playbook playbooks/stop-all.yml --check
```

### To Restart After Maintenance

```bash
# Restart all services
ansible-playbook playbooks/site.yml

# Restart services on specific machine
ansible-playbook playbooks/site.yml --limit orac
```

---

## Setup Playbook: setup-secrets.yml

**Purpose:** Generate required secrets (Beszel keypair) before first deployment.

### Usage

```bash
# Generate secrets
ansible-playbook playbooks/setup-secrets.yml

# This will:
# 1. Generate Beszel ED25519 keypair
# 2. Store keys in .secrets/ directory (git-ignored)
# 3. Display keys to add to vault
```

After running this, edit the vault to add the generated keys:

```bash
ansible-vault edit inventory/group_vars/all/vault.yml
```

---

## Common Workflow Patterns

### Initial Deployment

```bash
# 1. Generate secrets
ansible-playbook playbooks/setup-secrets.yml

# 2. Edit vault with generated secrets
ansible-vault edit inventory/group_vars/all/vault.yml

# 3. Test on one machine first (jarvis recommended - simplest)
ansible-playbook playbooks/site.yml --limit jarvis --check --diff

# 4. Deploy to test machine
ansible-playbook playbooks/site.yml --limit jarvis

# 5. Verify deployment
ansible-playbook playbooks/verify.yml --limit jarvis

# 6. Deploy to remaining machines
ansible-playbook playbooks/site.yml --limit seraph
ansible-playbook playbooks/site.yml --limit orac
```

### Update Single Service

```bash
# Update just Traefik on all machines
ansible-playbook playbooks/site.yml --tags traefik

# Update Traefik on specific machine
ansible-playbook playbooks/site.yml --tags traefik --limit orac
```

### Update Core Infrastructure

```bash
# Update all core services
ansible-playbook playbooks/deploy-core.yml

# Or use tags
ansible-playbook playbooks/site.yml --tags core-services
```

### Troubleshooting

```bash
# 1. Check current state
ansible-playbook playbooks/verify.yml --limit orac

# 2. Stop services
ansible-playbook playbooks/stop-all.yml --limit orac

# 3. Redeploy
ansible-playbook playbooks/site.yml --limit orac

# 4. Verify fix
ansible-playbook playbooks/verify.yml --limit orac
```

### System Maintenance

```bash
# 1. Stop all services
ansible-playbook playbooks/stop-all.yml

# 2. Perform maintenance (system updates, etc.)
ansible all -b -a "apt update && apt upgrade -y"

# 3. Reboot if needed
ansible all -b -a "reboot"

# 4. Wait for systems to come back up
sleep 60

# 5. Restart all services
ansible-playbook playbooks/site.yml
```

---

## Idempotency

All playbooks are **idempotent** - safe to run multiple times without causing issues.

**Testing idempotency:**
```bash
# Run twice - second run should show no changes
ansible-playbook playbooks/site.yml --limit jarvis
ansible-playbook playbooks/site.yml --limit jarvis  # Should be all "ok", minimal "changed"
```

---

## Advanced Usage

### Combining Options

```bash
# Deploy infrastructure to seraph, check mode, with verbose output
ansible-playbook playbooks/site.yml --limit seraph --tags infrastructure --check -v

# Deploy monitoring stack to all machines, show differences
ansible-playbook playbooks/site.yml --tags monitoring --diff

# Deploy everything except apps
ansible-playbook playbooks/site.yml --skip-tags apps
```

### Using Ansible Vault

```bash
# View vault contents
ansible-vault view inventory/group_vars/all/vault.yml

# Edit vault
ansible-vault edit inventory/group_vars/all/vault.yml

# Run playbook with vault password file
ansible-playbook playbooks/site.yml --vault-password-file=.ansible-vault-pass
```

### Debugging

```bash
# Verbose output
ansible-playbook playbooks/site.yml -v     # verbose
ansible-playbook playbooks/site.yml -vv    # more verbose
ansible-playbook playbooks/site.yml -vvv   # very verbose

# Step-by-step execution
ansible-playbook playbooks/site.yml --step

# Start at specific task
ansible-playbook playbooks/site.yml --start-at-task="Deploy Traefik"
```

---

## Machine-Specific Notes

### jarvis (Simplest - 7 services)
**Services:** docker-socket-proxy, traefik, beszel-agent, samba, dozzle, whatsupdocker, homeassistant
- No NAS mounts
- Good for testing
- Minimal dependencies

### seraph (Monitoring Hub - 11 services)
**Services:** All common + beszel (hub), adguardhome, uptime-kuma, watchyourlan, gocron
- Hosts Beszel hub
- AdGuard Home (DNS/DHCP)
- Most monitoring services

### orac (Full Stack - 17 services)
**Services:** All common + 11 application services
- NAS mounts required (music, roms, backups)
- Most complex setup
- Deploy last

---

## Deployment Dependencies

**Critical ordering:**
1. `tailscale` must run FIRST (VPN networking)
2. `docker` must run before ANY Docker services
3. `docker_socket_proxy` must run before `traefik`
4. `beszel` (hub) should run before `beszel_agent`
5. `nas_mounts` should run after `docker` (on orac)

The playbooks handle this ordering automatically.

---

## Conditional Execution

Services only deploy to machines that list them in their `services` variable:

```yaml
# inventory/host_vars/jarvis/vars.yml
services:
  - docker-socket-proxy
  - traefik
  - beszel-agent
  - samba
  - dozzle
  - whatsupdocker
  - homeassistant
```

This means you can safely run `site.yml` against all machines - only configured services will deploy.

---

## Getting Help

- **Syntax check:** `ansible-playbook playbooks/site.yml --syntax-check`
- **List tasks:** `ansible-playbook playbooks/site.yml --list-tasks`
- **List tags:** `ansible-playbook playbooks/site.yml --list-tags`
- **List hosts:** `ansible-playbook playbooks/site.yml --list-hosts`

For more information, see:
- `/docs/deployment.md` - Detailed deployment guide
- `/docs/configuration.md` - Configuration reference
- `/PLAN.md` - Implementation plan and progress
