# Actual Homelab Configuration

This document contains the real configuration details for your homelab setup. Use this as reference when implementing the Ansible infrastructure.

## Machine Details

### Hostnames
- **orac** - Machine 1
- **jarvis** - Machine 2  
- **seraph** - Machine 3

### Network
- **Access Method**: Tailscale VPN
- All machines are accessible via their Tailscale hostnames
- No need for IP addresses (Tailscale handles DNS)

### SSH Access
- **Username**: `danjam` (same on all machines)
- **Authentication**: SSH key (assumed configured in Tailscale)

### Docker Configuration
- **Base Directory**: `/opt/homelab` (all machines)
- Each service deployed to: `/opt/homelab/service-name/`
- Consistent across all three machines

### Domain Configuration
- **Root Domain**: `dannyjames.net`
- **Timezone**: `Europe/London`
- **User/Group IDs**: `1000:1000`

**Machine Subdomains:**
- `orac.dannyjames.net`
- `jarvis.dannyjames.net`
- `seraph.dannyjames.net`

**Service URL Pattern:**
- `service.machine.dannyjames.net` (e.g., `traefik.orac.dannyjames.net`)
- `service.dannyjames.net` (e.g., `beszel.dannyjames.net` - hub on seraph)

### Samba Shares
- **Purpose**: Server-only (no inter-machine mounts)
- **Port**: 445
- **Authentication**: Username `danjam`, password in .env
- **orac shares**: `/opt/shares/outbox`, `/opt/homelab/www`, `/opt`, `~/Dropbox`
- **jarvis shares**: `/opt` only
- **seraph shares**: `/opt` only

## Implementation Changes Needed

### 1. Update Inventory (`inventory/hosts.yml`)

Change from:
```yaml
all:
  children:
    homelab:
      hosts:
        machine1:
          ansible_host: 192.168.1.10
          ansible_user: youruser
```

To:
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

### 2. Rename Host Variables Directories

Rename:
- `host_vars/machine1/` → `host_vars/orac/`
- `host_vars/machine2/` → `host_vars/jarvis/`
- `host_vars/machine3/` → `host_vars/seraph/`

### 3. Update Host Variables Files

In each `host_vars/{orac,jarvis,seraph}/vars.yml`, update:

```yaml
# Before
hostname: machine1
domain: machine1.yourdomain.com

# After
hostname: orac  # or jarvis, seraph
domain: orac.yourdomain.com  # or jarvis.yourdomain.com, seraph.yourdomain.com
```

### 4. Update Documentation References

Update all documentation that mentions:
- "machine1/2/3" → "orac/jarvis/seraph"
- "192.168.1.x" → Tailscale hostname
- "youruser" → "danjam"

## Tailscale Specific Notes

### Advantages
- No need to manage IP addresses
- Built-in DNS resolution
- Secure by default
- Works across networks

### Ansible Connection
Ansible will use Tailscale's network automatically since hostnames resolve via Tailscale DNS.

### Testing Connectivity
```bash
# Test Tailscale connectivity
ping orac
ping jarvis
ping seraph

# Test SSH access
ssh danjam@orac
ssh danjam@jarvis
ssh danjam@seraph

# Test Ansible connectivity
ansible all -m ping
```

## Service Deployment Location

All services on all machines deploy to:
```
/opt/homelab/
├── traefik/
│   ├── docker-compose.yml
│   ├── config/
│   └── certs/
├── beszel/
│   └── docker-compose.yml
└── service-name/
    └── docker-compose.yml
```

This location is already configured in `inventory/group_vars/all/vars.yml`:
```yaml
homelab_dir: /opt/homelab
```

## Quick Start Commands

Once inventory is updated:

```bash
# Test connectivity to all machines
ansible all -m ping

# Deploy to specific machine
ansible-playbook playbooks/site.yml --limit orac
ansible-playbook playbooks/site.yml --limit jarvis
ansible-playbook playbooks/site.yml --limit seraph

# Deploy to all machines
ansible-playbook playbooks/site.yml
```

## Machine Roles

Define which services run on which machines in their respective `host_vars/` files:

### Suggested Service Distribution

**orac**:
```yaml
services:
  - traefik
  - beszel
  # Add orac-specific services
```

**jarvis**:
```yaml
services:
  - traefik
  - beszel
  # Add jarvis-specific services
```

**seraph**:
```yaml
services:
  - traefik
  - beszel
  # Add seraph-specific services
```

## External Dependencies

### NAS Mounts (orac only)

**orac mounts external NAS from 192.168.1.60:**

```bash
# /etc/fstab entries
//192.168.1.60/MUSIC    → /mnt/music
//192.168.1.60/ROMS     → /mnt/roms
//192.168.1.60/BACKUPS  → /mnt/backups
```

**Used by:** Navidrome music server (mounts /mnt/music)

**Credentials:** Stored in `/home/danjam/.smbcredentials` (not in Docker)

**Ansible Requirements:**
- Install `cifs-utils` package
- Create mount point directories
- Deploy credentials file securely (from ansible-vault)
- Manage `/etc/fstab` entries
- Ensure mounts exist before Docker starts

**Template Variables:**
```yaml
# host_vars/orac/vars.yml
nas_ip: 192.168.1.60
nas_mounts:
  - share: MUSIC
    mount_point: /mnt/music
  - share: ROMS
    mount_point: /mnt/roms
  - share: BACKUPS
    mount_point: /mnt/backups

# vault.yml
vault_nas_username: "username"
vault_nas_password: "password"
```

### DNS Server (seraph)

**seraph runs AdGuard Home (DNS server) and some containers depend on it:**

```yaml
# Hardcoded in docker-compose.yml
dns:
  - 192.168.1.1  # Should be templated as variable
```

**Containers affected:**
- beszel-agent (uses network_mode: host)
- watchyourlan (uses network_mode: host)

**Reason:** Circular dependency - can't use AdGuard Home for DNS while starting it

**Ansible Consideration:** Template the DNS IP as a variable

## Security Concerns Found

⚠️ **Current security issues to address during migration:**

1. **Plaintext passwords in .env files:**
   - `DEFAULT_PASSWORD=M00seontheL00se` (visible on all machines)
   - Samba, some service authentications use this
   
2. **API tokens in .env (not Docker secrets):**
   - Telegram bot tokens on jarvis and seraph
   - Last.fm and Spotify API keys on orac
   
3. **Mixed secret storage:**
   - Cloudflare: ✅ Docker secrets
   - Beszel: ✅ Docker secrets
   - Telegram: ❌ .env plaintext
   - Service passwords: ❌ .env plaintext

**Recommendation:** Move all secrets to ansible-vault and deploy as Docker secrets.

## Architecture Notes

**Current Setup:**
- Monolithic docker-compose.yml (all services in one file)
- Single `homelab` Docker network (not separated web/monitoring)
- HTTPS only (no port 80 exposed)
- Docker secrets used for Cloudflare and Beszel
- Traefik uses external config files (not inline)

**Migration Decision:**
- Keep monolithic structure (minimal disruption to working setup)
- Template docker-compose.yml with Jinja2 for per-machine service differences
- Maintain current network architecture (single homelab network)
- Standardize all secrets on Docker secrets (not .env)

## Notes

- Tailscale hostnames are already configured to work with Ansible
- No additional network configuration needed
- SSH keys should already be working via Tailscale
- The `/opt/homelab` directory will be created by Ansible if it doesn't exist
- No cross-machine dependencies (machines are self-contained)
