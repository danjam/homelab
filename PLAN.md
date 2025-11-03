# Migration Plan: Current Setup to Ansible-Managed Modular Infrastructure

## Overview

Migrate the existing monolithic docker-compose homelab setup to a modern Ansible-managed modular infrastructure where each service has its own docker-compose file and services communicate via external Docker networks.

**Timeline Estimate:** 15-24 hours total
**Risk Level:** Medium-High (architectural change to production system)
**Approach:** Phased rollout with service-by-service migration
**Improvement:** Modular structure for independent service management

---

## 📊 Implementation Progress (Updated 2025-01-11)

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 0: Pre-Migration | ⏭️ SKIPPED | Not needed - building automation, not migrating yet |
| **Phase 1: Security Foundation** | **✅ COMPLETE** | Single vault consolidated, all real credentials removed, beszel config fixed |
| **Phase 2: Ansible Structure** | **✅ COMPLETE** | Inventory configured with orac/jarvis/seraph, all vars set |
| **Phase 3: Core Infrastructure** | **✅ COMPLETE** | Tailscale ✅, Common ✅, Docker ✅, NAS ✅ |
| **Phase 3.0: Tailscale Role** | **✅ COMPLETE** | VPN networking with SSH, MagicDNS, minimal config |
| **Phase 3.1: Common Role** | **✅ COMPLETE** | Base system setup with packages, directories, update scripts |
| **Phase 3.2: Docker Role** | **✅ COMPLETE** | Docker CE, Compose v2, external networks (homelab, monitoring) |
| **Phase 3.3: NAS Mounts Role** | **✅ COMPLETE** | Systemd-based NAS mounting for all machines (BACKUPS on all) |
| **Phase 4.1: Docker Socket Proxy** | **✅ COMPLETE** | Independent role ready |
| **Phase 4.2: Traefik** | **✅ COMPLETE** | Depends on 4.1, ready to deploy |
| **Phase 4.3: Beszel Roles** | **✅ COMPLETE** | Hub + Agent roles ready, uses shared public key |
| **Phase 4.4: Samba** | **✅ COMPLETE** | File sharing role ready |
| Phase 5: Application Services | ⏸️ PARTIAL (DEFERRED) | 2 common services complete, 18 machine-specific deferred |
| **Phase 6: Playbooks** | **🎯 NEXT** | Orchestration playbooks - ready to create |
| Phase 7: Testing | 🔲 Not Started | Per-machine deployment testing |
| Phase 8: Documentation | 🔲 Not Started | End-user deployment guide |
| Phase 9: Repository Prep | 🔲 Not Started | Final git checks and secrets verification |

**Current Status:** Phases 1-4 COMPLETE. Phase 5 PARTIALLY COMPLETE - Common services (dozzle, whatsupdocker) complete, 18 machine-specific services deferred. Phase 6 (Playbooks) is NEXT.

**Next Steps:**
1. **Phase 6 (NOW)**: Create orchestration playbooks (`site.yml`)
2. Phase 7: Test deployment on jarvis (simplest machine)
3. Phase 8: Create end-user deployment guide
4. Phase 9: Repository prep and final verification
5. Phase 5 (LATER): Add remaining application services incrementally after core infrastructure validated
6. **THEN**: User fills secrets and deploys

**Important:** Secrets are filled at deployment time, not during build. The `playbooks/setup-secrets.yml` playbook generates required keys when the user is ready to deploy.

**Rationale for Deferring Phase 5:** We have enough services (10 roles) to validate the entire infrastructure stack. Adding remaining application services can be done incrementally after core infrastructure is proven working.

---

## Architecture Change

### Current (Monolithic)
```
/opt/homelab/
├── docker-compose.yml    # All 17 services in one file
├── .env                  # All variables
├── config/               # All configs mixed
└── data/                 # All data mixed
```

### Target (Modular)
```
/opt/homelab/
├── traefik/
│   ├── docker-compose.yml
│   ├── .env
│   ├── config/
│   └── certs/
├── beszel-agent/
│   ├── docker-compose.yml
│   └── .env
├── navidrome/
│   ├── docker-compose.yml
│   ├── .env
│   └── data/
└── (each service separate)
```

### Network Architecture

**Inter-Machine Networking (Tailscale):**
```
Control Machine ←→ Tailscale VPN ←→ orac / jarvis / seraph
```

**Docker Networks (Per-Machine):**
```
External Networks:
- homelab      → Traefik + all web services (actual implementation)
- monitoring   → Beszel hub + agents
- internal     → Per-service internal networks (databases, etc.)
- {hostname}_docker_socket → Docker Socket Proxy access
```

**⚠️ IMPLEMENTATION NOTE:** Actual implementation uses `homelab` network (not `web`) to match existing production setup on orac. This is a conscious decision to minimize disruption during migration.

---

## Phase 0: Pre-Migration Checklist

### Verify Current State
- [ ] Document all running services on each machine (docker ps output)
- [ ] Backup entire /opt/homelab directory on all machines
- [ ] Export current docker volumes: `docker volume ls`
- [ ] Test all services accessible and record URLs
- [ ] Document custom configurations
- [ ] Save current network configuration: `docker network ls`

### Prepare Development Environment
- [ ] Install Ansible on control machine
- [ ] Install ansible-galaxy collections:
  ```bash
  ansible-galaxy collection install community.docker
  ansible-galaxy collection install ansible.posix
  ```
- [ ] Clone homelab repository
- [ ] Create .ansible-vault-pass file with secure password
- [ ] Test SSH connectivity to all machines via Tailscale

### Create Test Environment (Recommended)
- [ ] Consider testing on VM/container first
- [ ] Or test on least critical machine (jarvis)

**Estimated Time:** 2-3 hours

---

## Phase 1: Security Foundation ✅ COMPLETE (Fixed 2025-11-02)

**Goal:** Vault structure for secrets management

### What Was Built:

1. **Single Vault Structure (Fixed 2025-11-02):**
   - `inventory/group_vars/all/vault.yml` - ONLY vault file containing ALL secrets
   - Host-specific vault files deleted (unnecessary complexity removed)
   - All placeholders use consistent `PLACEHOLDER_*` format
   - Real credentials removed and replaced with placeholders
   - Comprehensive documentation in vault file header

2. **Beszel Authentication:**
   - Research completed: All Beszel agents use ONE shared public key from hub
   - Hub generates ED25519 keypair on first start
   - Private key stays on hub, public key shared with all agents
   - No per-agent unique keys needed

3. **Automation:**
   - Created `playbooks/setup-secrets.yml` - Generates Beszel keypair automatically
   - Stores generated keys in `.secrets/` directory (git-ignored)
   - Displays keys for user to add to vault when ready to deploy

4. **Vars files:**
   - All reference vault variables (e.g., `{{ vault_cloudflare_email }}`)
   - Machine-specific service lists configured

### Secrets to Fill (At Deployment Time):
```yaml
# ALL secrets in: inventory/group_vars/all/vault.yml

# Auto-generated by setup-secrets.yml
vault_beszel_hub_private_key: "PLACEHOLDER_GENERATED_BY_SETUP_SECRETS"
vault_beszel_hub_public_key: "PLACEHOLDER_GENERATED_BY_SETUP_SECRETS"

# User-provided - External services
vault_cloudflare_email: "PLACEHOLDER_CLOUDFLARE_EMAIL"
vault_cloudflare_dns_token: "PLACEHOLDER_CLOUDFLARE_DNS_TOKEN"
vault_default_password: "PLACEHOLDER_DEFAULT_PASSWORD"
vault_telegram_bot_token: "PLACEHOLDER_TELEGRAM_BOT_TOKEN"
vault_telegram_chat_id: "PLACEHOLDER_TELEGRAM_CHAT_ID"

# User-provided - orac-specific
vault_lastfm_apikey: "PLACEHOLDER_LASTFM_API_KEY"
vault_lastfm_secret: "PLACEHOLDER_LASTFM_SECRET"
vault_spotify_id: "PLACEHOLDER_SPOTIFY_CLIENT_ID"
vault_spotify_secret: "PLACEHOLDER_SPOTIFY_CLIENT_SECRET"
vault_nas_username: "PLACEHOLDER_NAS_USERNAME"
vault_nas_password: "PLACEHOLDER_NAS_PASSWORD"
```

**Status:** Single vault structure complete. Fixed beszel_agent role to use shared public key. All variable references verified.

---

## Phase 2: Ansible Structure ✅ COMPLETE

**Goal:** Configure inventory and variables for all machines

### What Was Built:

1. **Inventory configured** (`inventory/hosts.yml`):
   - orac (ansible_host: orac, ansible_user: danjam)
   - jarvis (ansible_host: jarvis, ansible_user: danjam)
   - seraph (ansible_host: seraph, ansible_user: danjam)

2. **Global variables** (`inventory/group_vars/all/vars.yml`):
   - homelab_dir: /opt/homelab
   - timezone: Europe/London
   - domain_root: dannyjames.net
   - Docker networks: homelab, monitoring
   - Common settings (puid, pgid, restart policy)

3. **Host variables configured:**
```yaml
hostname: orac
subdomain: orac
domain: "{{ subdomain }}.{{ domain_root }}"

# Services to deploy
services:
  - docker-socket-proxy
  - traefik
  - beszel-agent
  - code-server
  - samba
  - dozzle
  - metube
  - it-tools
  - omni-tools
  - hugo
  - chartdb
  - sshwifty
  - chromadb
  - drawio
  - whatsupdocker
  - navidrome
  - portainer

# NAS mounts
nas_enabled: true
nas_ip: 192.168.1.60
nas_mounts:
  - share: MUSIC
    mount_point: /mnt/music
  - share: ROMS
    mount_point: /mnt/roms
  - share: BACKUPS
    mount_point: /mnt/backups

# Samba shares
samba_shares:
  - local_path: /opt/shares/outbox
    share_name: outbox
  - local_path: /opt/homelab/www
    share_name: www
  - local_path: /opt
    share_name: opt
  - local_path: ~/Dropbox
    share_name: dropbox

# Service-specific variables
navidrome_music_path: /mnt/music
lastfm_apikey: "{{ vault_lastfm_apikey }}"
lastfm_secret: "{{ vault_lastfm_secret }}"
spotify_id: "{{ vault_spotify_id }}"
spotify_secret: "{{ vault_spotify_secret }}"
```

**host_vars/jarvis/vars.yml:**
```yaml
hostname: jarvis
subdomain: jarvis
domain: "{{ subdomain }}.{{ domain_root }}"

services:
  - docker-socket-proxy
  - traefik
  - beszel-agent
  - samba
  - dozzle
  - whatsupdocker
  - homeassistant

samba_shares:
  - local_path: /opt
    share_name: opt

telegram_bot_token: "{{ vault_telegram_bot_token }}"
telegram_chat_id: "{{ vault_telegram_chat_id }}"
```

**host_vars/seraph/vars.yml:**
```yaml
hostname: seraph
subdomain: seraph
domain: "{{ subdomain }}.{{ domain_root }}"

services:
  - adguardhome
  - docker-socket-proxy
  - traefik
  - beszel
  - beszel-agent
  - samba
  - dozzle
  - uptime-kuma
  - watchyourlan
  - whatsupdocker
  - gocron

# DNS configuration
local_dns_server: 192.168.1.1

samba_shares:
  - local_path: /opt
    share_name: opt

# Beszel hub
beszel_hub_domain: beszel.{{ domain_root }}

telegram_bot_token: "{{ vault_telegram_bot_token }}"
telegram_chat_id: "{{ vault_telegram_chat_id }}"
```
**Status:** ✅ COMPLETE
- Complete inventory structure (orac, jarvis, seraph)
- Group and host variables defined
- Machine-specific configurations captured
- Service lists configured for all machines
- All vars files reference vault variables correctly

---

## Phase 3: Create Core Infrastructure Roles

### 3.0 Tailscale Role ✅ COMPLETE (2025-01-11)

**Role:** `roles/tailscale` - VPN networking layer

**Structure:**
```
roles/tailscale/
├── README.md (comprehensive documentation)
├── defaults/main.yml (minimal variables)
├── tasks/main.yml (installation, auth, verification)
└── handlers/main.yml (service restart)
```

**What Was Built:**

1. **Minimal "It Just Works" Approach:**
   - Only two flags: `--authkey` and `--ssh`
   - Trusts Tailscale's smart defaults for everything else
   - No unnecessary configuration or templates

2. **Installation:**
   - Adds Tailscale official GPG key and apt repository
   - Installs tailscale package
   - Starts and enables tailscaled service

3. **Authentication:**
   - Checks if already authenticated (idempotent)
   - Authenticates with reusable auth key from vault
   - Uses system hostname automatically

4. **Tailscale SSH Enabled:**
   - Eliminates need for SSH keys between machines
   - ACL-based access control from Tailscale admin
   - Automatic credential rotation

5. **Verification:**
   - Queries Tailscale status via JSON API
   - Displays connection info (IP, hostname, DNS name)
   - Asserts healthy connection state

**Features:**
- ✅ Automated authentication with reusable auth key
- ✅ Tailscale SSH (no SSH keys needed)
- ✅ MagicDNS automatic (Tailscale default)
- ✅ Uses system hostname (Tailscale default)
- ✅ Auto-updates enabled (Tailscale default)
- ✅ Idempotent and comprehensive verification

**Variables:**
```yaml
# inventory/group_vars/all/vault.yml
vault_tailscale_auth_key: "PLACEHOLDER_TAILSCALE_AUTH_KEY"

# defaults/main.yml (minimal)
tailscale_enable_ssh: true
```

**Tags:**
- `tailscale` - All tasks
- `tailscale-install` - Installation only
- `tailscale-auth` - Authentication only
- `tailscale-verify` - Verification only

**Ready for:** Testing on all machines as part of full deployment

---

### 3.1 Common Role ✅ COMPLETE (2025-11-02)

**Role:** `roles/common` - Implemented and ready for deployment

**Structure:**
```
roles/common/
├── README.md (118 lines - comprehensive documentation)
├── defaults/main.yml (default variables)
├── tasks/
│   └── main.yml (63 lines)
├── templates/
│   ├── update-docker.sh.j2 (89 lines)
│   └── update-ubuntu.sh.j2 (81 lines)
└── handlers/
    └── main.yml (empty - no handlers needed)
```

**What Was Built:**

1. **Package Installation** - Installs essential system packages:
   - Development tools: curl, wget, git, vim
   - System utilities: htop, tree, net-tools, dnsutils
   - Data tools: jq, unzip
   - Security: ca-certificates, gnupg, lsb-release

2. **Directory Structure** - Creates homelab base:
   ```
   /opt/homelab/
   ├── config/     # Service configurations
   ├── data/       # Service data
   ├── logs/       # Service logs
   └── secrets/    # Docker secrets (mode 0700)
   ```

3. **Update Scripts** - Deployed to /usr/local/bin:
   - **update-docker.sh**: Updates all containers or specific service, cleans old images
   - **update-ubuntu.sh**: System updates, checks for required reboots

**Features:**
- ✅ Templated scripts with machine-specific info (hostname, domain)
- ✅ Proper ownership and permissions (homelab user owns files)
- ✅ Secure secrets directory (0700 permissions)
- ✅ Comprehensive tagging for selective deployment
- ✅ Full documentation in README.md

**Ready for:** Testing on all machines as part of full deployment.

---

### 3.2 Docker Role ✅ COMPLETE (2025-11-02)

**Role:** `roles/docker` - Implemented and ready for deployment

**Structure:**
```
roles/docker/
├── README.md (286 lines - comprehensive documentation)
├── defaults/main.yml (28 lines)
├── handlers/main.yml (10 lines)
├── tasks/main.yml (135 lines)
└── templates/
    └── daemon.json.j2 (9 lines)
```

**What Was Built:**

1. **Docker Installation** - From official Docker repositories:
   - Docker CE (Community Edition) latest stable
   - Docker CLI for command-line interface
   - containerd.io runtime
   - Docker Compose v2 as plugin (not standalone)

2. **Docker Daemon Configuration:**
   - JSON file logging with rotation (10MB max, 3 files)
   - overlay2 storage driver for efficiency
   - Configuration deployed to /etc/docker/daemon.json
   - Automatic restart on configuration changes

3. **External Networks Created:**
   - `homelab` (172.20.0.0/16) - Primary network for web-accessible services
   - `monitoring` (172.21.0.0/16) - Dedicated network for monitoring services

4. **User Management:**
   - Homelab user added to docker group
   - Enables running docker commands without sudo
   - Requires logout/login for group membership to take effect

5. **Service Management:**
   - Docker service enabled for automatic startup
   - Service started and verified running
   - Socket readiness check before network creation

**Features:**
- ✅ Idempotent - safe to run multiple times
- ✅ Comprehensive tagging for selective deployment
- ✅ Verification steps for Docker and Compose versions
- ✅ External networks for service isolation and communication
- ✅ Full documentation with troubleshooting guide

**Tags Available:**
- `docker` - All docker tasks
- `docker-install` - Installation only
- `docker-config` - Configuration only
- `docker-users` - User group management only
- `docker-service` - Service management only
- `docker-networks` - Network creation only
- `docker-verify` - Verification only

**Ready for:** Testing on all machines as part of full deployment.

**Note:** Network naming uses `homelab` (not `web`) to match existing production setup.

### 3.3 NAS Mounts Role ✅ COMPLETE (2025-11-02)

**Role:** `roles/nas_mounts` - Implemented and ready for deployment

**Structure:**
```
roles/nas_mounts/
├── README.md (361 lines - comprehensive documentation)
├── defaults/main.yml (18 lines)
├── handlers/main.yml (13 lines)
├── tasks/main.yml (119 lines)
└── templates/
    ├── smbcredentials.j2 (3 lines)
    ├── nas-mount.mount.j2 (14 lines)
    └── nas-mount.automount.j2 (11 lines)
```

**What Was Built:**

1. **CIFS/SMB Mounting Infrastructure:**
   - Installs cifs-utils package for SMB support
   - Creates mount point directories with proper permissions
   - Secure credential storage in /root/.smbcredentials (mode 0600)

2. **Systemd Mount Units (preferred over fstab):**
   - Mount units define actual mount configuration
   - Automount units enable mount-on-demand behavior
   - Better error handling and boot safety
   - Integration with journalctl logging

3. **Per-Machine Configuration:**
   - **orac**: 3 shares (MUSIC, ROMS, BACKUPS)
   - **jarvis**: 1 share (BACKUPS)
   - **seraph**: 1 share (BACKUPS)

4. **Automount Features:**
   - Lazy mounting (mount on first access)
   - Auto-unmount after 300 seconds of inactivity
   - Reduces resource usage for unused shares
   - Transparent to applications

5. **Network Dependencies:**
   - Waits for network-online.target
   - nofail option prevents boot hangs
   - Proper systemd dependency chain

**Features:**
- ✅ Systemd-based (more reliable than fstab)
- ✅ Automount capability for efficiency
- ✅ Secure credential management
- ✅ Comprehensive verification and health checks
- ✅ Full documentation with troubleshooting
- ✅ Idempotent - safe to run multiple times

**Tags Available:**
- `nas` - All NAS mount tasks
- `nas-install` - Install cifs-utils only
- `nas-dirs` - Create mount directories only
- `nas-credentials` - Deploy credentials file only
- `nas-systemd` - Create systemd units only
- `nas-mount` - Enable and start mounts only
- `nas-verify` - Verification only

**Ready for:** Testing on all machines as part of full deployment.

**Deliverables:**
- ✅ Working common role
- ✅ Docker installed with external networks created (homelab, monitoring)
- ✅ NAS mounts configured for all machines (systemd-based)

**Estimated Time:** 2-3 hours (COMPLETED)

---

## Phase 4: Create Service Roles (Core Services First)

Create one role per service. Start with core infrastructure services.

---

### ✅ IMPLEMENTATION STATUS (Updated 2024-11-01)

**Phases 4.1 and 4.2 COMPLETE** - Docker Socket Proxy and Traefik roles implemented and ready for deployment.

**Key Implementation Notes:**
- ✅ Based on actual production setup found on orac (not theoretical plan)
- ✅ Roles created as independent, reusable modules
- ⚠️ **Network naming differs from plan**: Uses `homelab` network (not `web`) to match current setup
- ⚠️ **Directory structure differs**: Uses shared `/opt/homelab/config/data/logs/secrets` (not per-service subdirs)
- ⚠️ **HTTPS only**: No port 80 exposed (differs from plan's port 80+443)
- ✅ Docker Socket Proxy is fully independent and reusable by other services
- ✅ Comprehensive documentation created (841 lines across 3 docs)

**Files Created:**
```
roles/docker_socket_proxy/    # 5 files, 431 lines
roles/traefik/                # 7 files, 495 lines  
docs/traefik-implementation.md
docs/traefik-refactoring.md
REFACTORING-COMPLETE.md
```

**See:** `REFACTORING-COMPLETE.md` for full implementation details.

**Ready for:** Testing on jarvis, then deployment to all machines.

---

### 4.1 Docker Socket Proxy Role

**Role:** `roles/docker_socket_proxy`

**Structure:**
```
roles/docker_socket_proxy/
├── tasks/
│   └── main.yml
├── templates/
│   ├── docker-compose.yml.j2
│   └── .env.j2
├── defaults/
│   └── main.yml
└── handlers/
    └── main.yml
```

**docker-compose.yml template:**
```yaml
services:
  docker-socket-proxy:
    image: ghcr.io/linuxserver/socket-proxy:latest
    container_name: docker-socket-proxy
    restart: {{ default_container_restart_policy }}
    environment:
      - CONTAINERS=1
      - INFO=1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - internal

networks:
  internal:
    name: {{ hostname }}_docker_socket
    driver: bridge
```

### 4.2 Traefik Role

**Role:** `roles/traefik`

**Most complex service - needs:**
- Static configuration file (traefik.yml)
- Dynamic configuration file (dynamic.yaml)
- Docker secrets for Cloudflare
- External web network
- Connection to docker-socket-proxy

**docker-compose.yml template:**
```yaml
services:
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: {{ default_container_restart_policy }}
    ports:
      - "443:443"
    environment:
      - CF_API_EMAIL_FILE=/run/secrets/cloudflare_email
      - CF_DNS_API_TOKEN_FILE=/run/secrets/cloudflare_dns_token
    volumes:
      - ./config:/etc/traefik
      - ./certs:/certs
    networks:
      - web
      - {{ hostname }}_docker_socket
    secrets:
      - cloudflare_email
      - cloudflare_dns_token
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(`traefik.{{ domain }}`)"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.service=api@internal"

networks:
  web:
    name: web
    external: true
  {{ hostname }}_docker_socket:
    external: true

secrets:
  cloudflare_email:
    file: {{ secrets_base_path }}/cloudflare_email
  cloudflare_dns_token:
    file: {{ secrets_base_path }}/cloudflare_dns_token
```

**Tasks:**
- Create traefik directory structure
- Deploy Docker secrets for Cloudflare
- Deploy static config (traefik.yml)
- Deploy dynamic config (dynamic.yaml)
- Deploy docker-compose.yml
- Start Traefik
- Wait for healthy status

### 4.3 Beszel Roles

**Two roles needed:**

**Role:** `roles/beszel_agent` (all machines)
```yaml
services:
  beszel-agent:
    image: henrygd/beszel-agent
    container_name: beszel-agent
    restart: {{ default_container_restart_policy }}
    network_mode: host
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      PORT: 45876
      KEY: {{ vault_beszel_agent_key }}
```

**Role:** `roles/beszel` (seraph only - the hub)
```yaml
services:
  beszel:
    image: henrygd/beszel
    container_name: beszel
    restart: {{ default_container_restart_policy }}
    volumes:
      - ./data:/data
    networks:
      - web
      - monitoring
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.beszel.rule=Host(`{{ beszel_hub_domain }}`)"
      - "traefik.http.routers.beszel.entrypoints=websecure"
      - "traefik.http.services.beszel.loadbalancer.server.port=8090"

networks:
  web:
    external: true
  monitoring:
    external: true
```

### ✅ 4.4 Samba Role - COMPLETE (2025-11-02)

**Role:** `roles/samba` - Implemented and ready for deployment

**Key Features:**
- ✅ Machine-specific share configuration via `samba_shares` variable
- ✅ Supports multiple shares per machine with individual settings
- ✅ Per-share browseable and writable configuration
- ✅ Authentication with username/password
- ✅ Secure .env file with restricted permissions (0600)
- ✅ Automatic directory creation (except home directories)
- ✅ Comprehensive README with examples for all machines

**Files Created:**
```
roles/samba/
├── README.md (81 lines)
├── defaults/main.yml (31 lines)
├── handlers/main.yml (8 lines)
├── tasks/main.yml (58 lines)
└── templates/
    ├── docker-compose.yml.j2 (28 lines)
    └── .env.j2 (6 lines)
```

**Machine Configurations:**
- orac: 4 shares (outbox, www, opt, dropbox)
- jarvis: 1 share (opt)
- seraph: 1 share (opt)

**Ready for:** Testing on all machines once vault configuration is complete.

---

### 4.4 Samba Role (REFERENCE)

**Role:** `roles/samba`

**Template handles different shares per machine:**
```yaml
services:
  samba:
    image: ghcr.io/servercontainers/samba:latest
    container_name: samba
    restart: {{ default_container_restart_policy }}
    ports:
      - "445:445"
    environment:
      - ACCOUNT_{{ default_username }}={{ default_password }}
      - UID={{ puid }}
      - GID={{ pgid }}
    volumes:
{% for share in samba_shares %}
      - {{ share.local_path }}:/shares/{{ share.share_name }}
{% endfor %}
```

**Deliverables:**
- Core service roles created (Docker Socket Proxy, Traefik, Beszel hub/agent, Samba)
- Each service has own directory and docker-compose
- Services connect via external networks
- Traefik properly configured with Cloudflare

**Estimated Time:** 4-6 hours for core services (COMPLETE)

---

## Phase 5: Create Application Service Roles

For each remaining service, create a role following the pattern:

### Service Role Template

```
roles/SERVICE_NAME/
├── tasks/
│   └── main.yml
├── templates/
│   ├── docker-compose.yml.j2
│   └── .env.j2 (if needed)
├── defaults/
│   └── main.yml (default variables)
└── handlers/
    └── main.yml
```

### Services to Create Roles For:

**orac specific:**
- code-server (VS Code web - web network)
- dozzle (log viewer - web network)
- metube (YouTube downloader - web network)
- it-tools (developer tools - web network)
- omni-tools (tools - web network)
- hugo (static site - web network)
- chartdb (database tool - web network)
- sshwifty (web SSH - web network)
- chromadb (vector database - web network + internal)
- drawio (diagrams - web network)
- whatsupdocker (update checker - docker socket network)
- navidrome (music server - web network + NAS mount)
- portainer (container management - web network + docker socket)

**jarvis specific:**
- dozzle (log viewer - web network)
- whatsupdocker (update checker - docker socket network)
- homeassistant (home automation - web network + host network)

**seraph specific:**
- dozzle (log viewer - web network)
- whatsupdocker (update checker - docker socket network)
- adguardhome (DNS/DHCP - host network, hardcoded DNS)
- uptime-kuma (monitoring - web network)
- watchyourlan (network scanner - host network, hardcoded DNS)
- gocron (scheduler - web network or internal)

### Key Patterns:

**Web-accessible service:**
```yaml
networks:
  - web
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.SERVICE.rule=Host(`SERVICE.{{ domain }}`)"
```

**Monitoring service:**
```yaml
networks:
  - monitoring
```

**Service with database:**
```yaml
services:
  app:
    networks:
      - web
      - internal
  
  database:
    networks:
      - internal

networks:
  web:
    external: true
  internal:
    name: SERVICE_internal
    driver: bridge
```

**Service needing Docker access:**
```yaml
networks:
  - {{ hostname }}_docker_socket
```

**Deliverables:**
- Role for each service
- Each service isolated in own directory
- Proper network assignments
- Traefik labels for web services

**Estimated Time:** 6-8 hours (18+ services total)

---

## Phase 6: Create Playbooks

### 6.1 Main Site Playbook

**File:** `playbooks/site.yml`
```yaml
---
- name: Deploy Homelab Infrastructure
  hosts: homelab
  become: true
  
  pre_tasks:
    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: yes
        cache_valid_time: 3600
  
  roles:
    # Core infrastructure
    - role: common
      tags: ['common', 'base']
    
    - role: docker
      tags: ['docker', 'base']
    
    - role: nas_mounts
      when: nas_enabled | default(false)
      tags: ['nas', 'mounts']
    
    # Core services (order matters)
    - role: docker_socket_proxy
      when: "'docker-socket-proxy' in services"
      tags: ['docker-socket-proxy', 'core']
    
    - role: traefik
      when: "'traefik' in services"
      tags: ['traefik', 'core']
    
    # Monitoring
    - role: beszel
      when: "'beszel' in services"
      tags: ['beszel', 'monitoring']
    
    - role: beszel_agent
      when: "'beszel-agent' in services"
      tags: ['beszel-agent', 'monitoring']
    
    # Common services
    - role: samba
      when: "'samba' in services"
      tags: ['samba', 'common']
    
    # Application services
    - role: code_server
      when: "'code-server' in services"
      tags: ['code-server', 'tools']
    
    - role: navidrome
      when: "'navidrome' in services"
      tags: ['navidrome', 'media']
    
    - role: homeassistant
      when: "'homeassistant' in services"
      tags: ['homeassistant', 'automation']
    
    - role: adguardhome
      when: "'adguardhome' in services"
      tags: ['adguardhome', 'network']
    
    # ... (include all other service roles)
```

### 6.2 Service-Specific Playbooks

**File:** `playbooks/deploy-traefik.yml`
```yaml
---
- name: Deploy Traefik Only
  hosts: homelab
  become: true
  
  roles:
    - role: traefik
      when: "'traefik' in services"
```

**File:** `playbooks/deploy-core.yml`
```yaml
---
- name: Deploy Core Services Only
  hosts: homelab
  become: true
  
  roles:
    - role: common
    - role: docker
    - role: docker_socket_proxy
      when: "'docker-socket-proxy' in services"
    - role: traefik
      when: "'traefik' in services"
```

### 6.3 Maintenance Playbooks

**File:** `playbooks/update-images.yml`
```yaml
---
- name: Update All Docker Images
  hosts: homelab
  become: true
  
  tasks:
    - name: Pull latest images for all services
      community.docker.docker_compose_v2:
        project_src: "{{ homelab_dir }}/{{ item }}"
        pull: always
        recreate: always
      loop: "{{ services }}"
      when: item in services
```

**Deliverables:**
- Main site.yml playbook with proper ordering
- Service-specific playbooks for targeted deployments
- Maintenance playbooks for updates
- Proper role ordering and dependencies

**Estimated Time:** 2-3 hours

---

## Phase 7: Migration Testing Strategy

### 7.1 Pre-Migration Validation
```bash
# Syntax check
ansible-playbook playbooks/site.yml --syntax-check

# Dry run on all machines
ansible-playbook playbooks/site.yml --check --diff

# Test connectivity
ansible all -m ping
```

### 7.2 Migration Approach: Service-by-Service

Instead of all-at-once, migrate services one by one:

**Strategy:**
1. Keep old monolithic compose running
2. Deploy new modular service
3. Stop old service from monolith
4. Verify new service works
5. Move to next service

**Example for Traefik:**
```bash
# 1. Deploy new modular Traefik
ansible-playbook playbooks/deploy-traefik.yml --limit orac

# 2. SSH to machine
ssh danjam@orac

# 3. Stop old Traefik in monolith
cd /opt/homelab
docker compose stop traefik

# 4. Verify new Traefik running
cd /opt/homelab/traefik
docker compose ps
curl https://traefik.orac.dannyjames.net

# 5. If works, remove from old compose
# Edit old docker-compose.yml, comment out traefik service
```

### 7.3 Test Machine Order

**Test on jarvis first (simplest - only 8 services):**

1. Deploy base infrastructure
```bash
ansible-playbook playbooks/site.yml --limit jarvis --tags base
```

2. Deploy core services one at a time
```bash
ansible-playbook playbooks/site.yml --limit jarvis --tags docker-socket-proxy
ansible-playbook playbooks/site.yml --limit jarvis --tags traefik
ansible-playbook playbooks/site.yml --limit jarvis --tags beszel-agent
```

3. Migrate remaining services
```bash
ansible-playbook playbooks/site.yml --limit jarvis --tags code-server
ansible-playbook playbooks/site.yml --limit jarvis --tags samba
ansible-playbook playbooks/site.yml --limit jarvis --tags homeassistant
# etc...
```

4. Once all services migrated, remove old monolith
```bash
ssh danjam@jarvis
cd /opt/homelab
mv docker-compose.yml docker-compose.yml.old
rm .env
```

**Then seraph (monitoring hub - 12 services):**
- Same process as jarvis
- Extra care with AdGuard Home (DNS dependency)
- Beszel hub must work before removing old

**Finally orac (most complex - 17 services):**
- Same process
- Extra step: verify NAS mounts before starting services
- Test Navidrome can access /mnt/music

### 7.4 Validation Checklist Per Machine

- [ ] All Docker networks created (docker network ls)
- [ ] All services have their own directory (ls /opt/homelab)
- [ ] Each service running (docker ps)
- [ ] Web services accessible via Traefik
- [ ] Beszel agent reporting to hub
- [ ] No errors in logs (docker logs <container>)
- [ ] Old monolith stopped and moved aside
- [ ] Can re-deploy service with Ansible

**Deliverables:**
- All three machines migrated to modular structure
- Old monolithic compose files backed up
- All services running and accessible
- Documentation of any issues encountered

**Estimated Time:** 4-6 hours (includes troubleshooting)

---

## Phase 8: Documentation

### 8.1 Update Existing Docs

**setup.md:**
- Update with actual machine names
- Add modular structure explanation
- Network architecture diagram

**secrets.md:**
- Document all vault variables
- Include key generation commands
- Add troubleshooting for decryption

**deployment.md:**
- Add examples for deploying individual services
- Document service dependencies
- Add troubleshooting section

### 8.2 Create New Documentation

**File:** `docs/architecture.md`
```markdown
# Architecture Overview

## Service Structure
- Each service in own directory
- Independent docker-compose files
- External networks for communication

## Network Architecture
- web: Traefik + web-accessible services
- monitoring: Beszel hub + agents
- <service>_internal: Per-service databases

## Service Dependencies
- Traefik → docker-socket-proxy
- All web services → Traefik
- Beszel agents → Beszel hub
- AdGuard Home → Must start first (seraph)
```

**File:** `docs/troubleshooting.md`
```markdown
# Troubleshooting Guide

## Service Won't Start
1. Check logs: docker logs <container>
2. Check network exists: docker network ls
3. Check secrets deployed: ls /opt/homelab/secrets

## Network Issues
- Verify external networks created
- Check service is in correct network
- Test connectivity between containers

## Traefik Not Routing
- Check labels in docker-compose.yml
- Verify service in web network
- Check Traefik logs
```

**File:** `docs/adding-services.md`
- Already exists, verify it matches new structure
- Update examples to use external networks
- Add network selection guidance

### 8.3 Repository README

Update main README.md:
```markdown
# Homelab Infrastructure

Ansible-managed modular homelab with Docker Compose.

## Features
- Modular service architecture
- External Docker networks
- Encrypted secrets with ansible-vault
- Traefik reverse proxy with Cloudflare DNS
- Beszel monitoring

## Quick Start
See [docs/setup.md](docs/setup.md)

## Architecture
See [docs/architecture.md](docs/architecture.md)
```

**Deliverables:**
- Complete and accurate documentation
- Architecture diagrams
- Troubleshooting guide
- Updated README

**Estimated Time:** 2-3 hours

---

## Phase 9: Repository Preparation

### 9.1 Create .gitignore

```gitignore
# Ansible
*.retry
.ansible-vault-pass
*.log

# Secrets (unencrypted)
**/vault.yml.unencrypted
.env
*.env
!*.env.example

# OS
.DS_Store
*.swp
*.swo
*~

# IDE
.vscode/
.idea/

# Backups
*.backup
*.bak
*.old

# Test environments
test/
```

### 9.2 Verify No Secrets Exposed

```bash
# Search for exposed secrets
grep -r "M00seontheL00se" . --exclude-dir=.git
grep -r "d.s.james@gmail.com" . --exclude-dir=.git --exclude="*.md"
grep -r "AAAAC3NzaC1" . --exclude-dir=.git

# Verify all vaults encrypted
find . -name "vault.yml" -exec head -1 {} \;
# All should show: $ANSIBLE_VAULT;1.1;AES256

# Check for API keys/tokens
grep -r "apikey" . --exclude-dir=.git
grep -r "token" . --exclude-dir=.git --exclude="*.md"
```

### 9.3 Create Example Files

**File:** `.env.example`
```bash
# Example environment file
# Copy to .env and fill in actual values

PUID=1000
PGID=1000
TZ=Europe/London
```

**File:** `vault.yml.example`
```yaml
---
# Example vault file structure
# DO NOT put real secrets here

vault_cloudflare_email: "your-email@example.com"
vault_cloudflare_dns_token: "your-token-here"
vault_default_password: "your-secure-password"
```

### 9.4 Initial Commit

```bash
git init
git add .
git commit -m "Initial commit: Modular Ansible-managed homelab infrastructure

- Modular service architecture
- External Docker networks
- Encrypted secrets with ansible-vault
- Service roles for all applications
- Comprehensive documentation"
```

### 9.5 Create GitHub Repository and Push

```bash
# Create repo on GitHub first, then:
git remote add origin git@github.com:yourusername/homelab.git
git branch -M main
git push -u origin main
```

**Deliverables:**
- Clean repository with no secrets
- Proper .gitignore
- Example files for reference
- Initial commit to GitHub
- All vault files encrypted

**Estimated Time:** 1-2 hours

---

## Rollback Plan

### Per-Service Rollback

If a service fails after migration:

```bash
# Stop new service
cd /opt/homelab/service-name
docker compose down

# Start old service from monolith
cd /opt/homelab
# Uncomment service in old docker-compose.yml
docker compose up -d service-name
```

### Machine-Level Rollback

If entire machine fails:

```bash
# Stop all new services
cd /opt/homelab
for dir in */; do
  cd "$dir"
  docker compose down 2>/dev/null || true
  cd ..
done

# Restore old monolith
mv docker-compose.yml.old docker-compose.yml
docker compose up -d
```

### Full Rollback (Nuclear Option)

```bash
# On each machine
ssh machine
cd /opt/homelab

# Remove new structure
rm -rf */

# Restore from backup
tar xzf /root/homelab-backup-YYYYMMDD.tar.gz

# Start old setup
docker compose up -d
```

**Keep backups for at least 2 weeks after migration**

---

## Success Criteria

**Infrastructure:**
- [ ] All secrets encrypted in ansible-vault
- [ ] No plaintext credentials in repository
- [ ] External Docker networks created (web, monitoring)
- [ ] NAS mounts working on orac

**Services:**
- [ ] Each service in own directory with docker-compose.yml
- [ ] All services running and accessible
- [ ] Traefik routing all web services correctly
- [ ] Beszel monitoring all three machines
- [ ] All service-specific features working (music playback, home automation, etc.)

**Operational:**
- [ ] Can deploy/update individual services via Ansible
- [ ] Can deploy entire stack via Ansible
- [ ] Service logs accessible via Dozzle
- [ ] Can add new services easily

**Documentation:**
- [ ] Setup guide accurate and complete
- [ ] Architecture documented with diagrams
- [ ] Troubleshooting guide created
- [ ] All secrets documented in example files

**Repository:**
- [ ] Code pushed to GitHub
- [ ] All vault files encrypted
- [ ] No secrets exposed
- [ ] README complete

---

## Post-Migration Tasks

### Week 1
- [ ] Monitor all services for stability
- [ ] Check logs daily for errors
- [ ] Verify backups working
- [ ] Test re-deployment from scratch

### Week 2
- [ ] Test individual service updates
- [ ] Verify Traefik certificate renewal
- [ ] Check Beszel monitoring graphs
- [ ] Document any issues found

### Month 1
- [ ] Remove old backup files (after confirming stable)
- [ ] Rotate secrets (generate new keys)
- [ ] Performance review (any improvements?)
- [ ] Consider CI/CD pipeline (GitHub Actions for validation)

### Ongoing
- [ ] Regular secret rotation schedule (quarterly)
- [ ] Keep Ansible collections updated
- [ ] Document new services as added
- [ ] Review and update documentation

---

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Secrets leaked to GitHub | CRITICAL | Low | Multiple verification steps, pre-commit checks |
| Service networking issues | HIGH | Medium | Test on one machine first, maintain rollback |
| NAS mounts fail (orac) | HIGH | Low | Test mount role separately, verify before services |
| DNS circular dependency (seraph) | MEDIUM | Low | AdGuard Home deploys first, hardcoded DNS as fallback |
| Data loss during migration | HIGH | Low | Keep old compose running until verified |
| Lost vault password | HIGH | Very Low | Store in password manager, document recovery |
| Service dependencies broken | MEDIUM | Medium | Deploy services in correct order, test dependencies |
| Traefik routing fails | HIGH | Low | Deploy Traefik first, verify before other services |

---

## Benefits of Modular Architecture

### What We Gain

**Operational:**
- Update Traefik without restarting all services
- Deploy new services without affecting existing ones
- Easier to troubleshoot individual services
- Clear separation of concerns

**Maintenance:**
- Update one service without affecting others
- Remove services cleanly (just delete directory)
- Easy to see what's deployed (one directory per service)
- Service-specific configurations isolated

**Development:**
- Test new services in isolation
- Easy to share service configurations
- Clear service boundaries
- Better aligned with infrastructure-as-code practices

**Scalability:**
- Easy to move services between machines
- Can scale services independently
- Clear network architecture
- Ready for future container orchestration (k8s) if needed

---

## Timeline Summary

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 0: Pre-Migration | 2-3h | None |
| Phase 1: Security | 2-4h | Phase 0 |
| Phase 2: Structure | 2-3h | Phase 1 |
| Phase 3: Core Infrastructure | 2-3h | Phase 2 |
| Phase 4: Core Service Roles | 4-6h | Phase 3 |
| Phase 5: App Service Roles | 6-8h | Phase 4 |
| Phase 6: Playbooks | 2-3h | Phase 5 |
| Phase 7: Migration Testing | 4-6h | Phase 6 |
| Phase 8: Documentation | 2-3h | Phase 7 (can parallelize) |
| Phase 9: Repository | 1-2h | Phase 8 |
| **Total** | **27-41h** | Sequential phases |

**Realistic Timeline:** 
- Part-time (evenings): 1-2 weeks
- Dedicated effort: 4-5 days
- Conservative with testing: 2 weeks

---

## Final Notes

- This migration improves maintainability significantly
- Take time to test each service thoroughly
- Keep old setup intact until fully confident
- Document everything you learn along the way
- Don't rush - a working system is more important than speed
- The modular structure will save time in the long run
