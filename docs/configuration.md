# Configuration Guide

## Machine Configuration

### Hostnames and Access
- **orac**, **jarvis**, **seraph**
- Access via Tailscale VPN (hostnames resolve automatically)
- SSH user: `danjam` (consistent across all machines)
- Base directory: `/opt/homelab/`

### Domain Configuration
- **Root domain**: `dannyjames.net`
- **Timezone**: `Europe/London`
- **User/Group**: `danjam:danjam` (1000:1000)

**Machine domains:**
- `orac.dannyjames.net`
- `jarvis.dannyjames.net`
- `seraph.dannyjames.net`

**Service URL pattern:**
- `service.{machine}.dannyjames.net` (e.g., `traefik.orac.dannyjames.net`)
- `service.dannyjames.net` (for hub services like `beszel.dannyjames.net`)

## Inventory Structure

### Location
`inventory/hosts.yml` - Defines all machines

### Configuration
```yaml
all:
  children:
    homelab:
      hosts:
        orac:
          ansible_host: orac
          ansible_user: danjam
        jarvis:
          ansible_host: jarvis
          ansible_user: danjam
        seraph:
          ansible_host: seraph
          ansible_user: danjam
```

## Variable Hierarchy

### Global Variables
`inventory/group_vars/all/vars.yml` - Shared across all machines:
- `homelab_dir: /opt/homelab`
- `domain_root: dannyjames.net`
- `timezone: Europe/London`
- `puid: 1000` / `pgid: 1000`
- Docker network names
- Container restart policy

### Host Variables
`host_vars/{orac,jarvis,seraph}/vars.yml` - Machine-specific:
- `hostname` - Machine hostname
- `subdomain` - Machine subdomain
- `domain` - Full domain (e.g., `orac.dannyjames.net`)
- `services` - List of services to deploy
- Service-specific variables (paths, ports, etc.)
- NAS configuration (orac only)
- Samba shares configuration

### Secrets
`inventory/group_vars/all/vault.yml` - ALL secrets (encrypted):
- Cloudflare credentials
- API tokens
- Service passwords
- NAS credentials
- Generated keys

## Service Distribution

### orac (19 total services)
**Common services (6):**
- docker-socket-proxy, traefik, beszel-agent, samba, dozzle, whatsupdocker

**Unique services (13):**
- code-server, portainer, navidrome, metube, it-tools, omni-tools, hugo, chartdb, sshwifty, chromadb, drawio

**Special configuration:**
- NAS mounts from 192.168.1.60 (MUSIC, ROMS, BACKUPS)
- Last.fm and Spotify API for Navidrome
- 4 Samba shares

### jarvis (7 total services)
**Common services (6):**
- docker-socket-proxy, traefik, beszel-agent, samba, dozzle, whatsupdocker

**Unique services (1):**
- homeassistant

**Special configuration:**
- 1 Samba share
- Telegram notifications

### seraph (11 total services)
**Common services (6):**
- docker-socket-proxy, traefik, beszel-agent, samba, dozzle, whatsupdocker

**Hub services (1):**
- beszel (monitoring hub)

**Unique services (4):**
- adguardhome, uptime-kuma, watchyourlan, gocron

**Special configuration:**
- Hosts Beszel hub (other machines connect to it)
- 1 Samba share
- Telegram notifications
- Hardcoded DNS for circular dependency

## Network Architecture

### External Networks
Created by Docker role, used by all services:
- **homelab** (172.20.0.0/16) - Web-accessible services + Traefik
- **monitoring** (172.21.0.0/16) - Monitoring services (Beszel)

### Per-Machine Networks
- **{hostname}_docker_socket** - Bridge network for Docker Socket Proxy access
  - Example: `orac_docker_socket`, `jarvis_docker_socket`
  - Isolates Docker API access

### Service-Specific Networks
Some services create internal networks:
- `{service}_internal` - For service + database communication

## Storage Configuration

### orac NAS Mounts
Mounted via systemd (not fstab):
- `/mnt/music` ← //192.168.1.60/MUSIC (for Navidrome)
- `/mnt/roms` ← //192.168.1.60/ROMS
- `/mnt/backups` ← //192.168.1.60/BACKUPS

Credentials stored in vault, deployed securely.

### Samba Shares
Each machine exports local directories via Samba:

**orac (4 shares):**
- `/opt/shares/outbox`
- `/opt/homelab/www`
- `/opt`
- `~/Dropbox`

**jarvis & seraph (1 share each):**
- `/opt`

## Security Architecture

### Docker Socket Security
- **No direct socket mounts** - All services use Docker Socket Proxy
- Docker Socket Proxy runs on isolated network
- Read-only Docker API access

### Secret Management
- Single encrypted vault file
- Docker secrets for sensitive data (Cloudflare, Beszel)
- Environment variables templated from vault
- `.ansible-vault-pass` never committed to git

### HTTPS Only
- Traefik enforces HTTPS
- No port 80 exposed
- Automatic Let's Encrypt certificates via Cloudflare DNS

### Service Isolation
- Each service in own docker-compose file
- Services communicate via external networks
- Principle of least privilege

## Configuration Files

### ansible.cfg
Project-wide Ansible configuration:
- Vault password file location
- SSH settings
- Collection paths

### Global Variables Example
```yaml
# inventory/group_vars/all/vars.yml
homelab_dir: /opt/homelab
domain_root: dannyjames.net
timezone: Europe/London
puid: 1000
pgid: 1000
docker_user: danjam
container_restart_policy: unless-stopped

# Docker networks
docker_network_homelab: homelab
docker_network_monitoring: monitoring
```

### Host Variables Example
```yaml
# host_vars/orac/vars.yml
hostname: orac
subdomain: orac
domain: "{{ subdomain }}.{{ domain_root }}"

services:
  - docker-socket-proxy
  - traefik
  - beszel-agent
  - samba
  - dozzle
  - whatsupdocker
  - navidrome
  # ... more services

# NAS configuration
nas_enabled: true
nas_ip: 192.168.1.60
nas_mounts:
  - share: MUSIC
    mount_point: /mnt/music
  - share: ROMS
    mount_point: /mnt/roms
  - share: BACKUPS
    mount_point: /mnt/backups

# Service-specific
navidrome_music_path: /mnt/music
lastfm_apikey: "{{ vault_lastfm_apikey }}"
```

## Modifying Configuration

### Adding a Service to a Machine
1. Edit `host_vars/{machine}/vars.yml`
2. Add service to `services` list
3. Add any service-specific variables
4. Add secrets to vault if needed
5. Deploy with `--tags servicename`

### Changing Global Settings
Edit `inventory/group_vars/all/vars.yml` - affects all machines.

### Adding Secrets
```bash
ansible-vault edit inventory/group_vars/all/vault.yml
```

### Changing Machine-Specific Settings
Edit `host_vars/{orac,jarvis,seraph}/vars.yml` - affects only that machine.

## Best Practices

1. **Use variables, not hardcoded values** - Everything should be templatable
2. **Document defaults** - Use `defaults/main.yml` in roles
3. **Single source of truth** - Variables in host_vars, secrets in vault
4. **Test with --check** - Dry run before deploying
5. **Use tags** - For selective deployment
6. **Keep secrets in vault** - Never in plaintext files
