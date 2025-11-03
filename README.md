# Homelab Infrastructure

Ansible-based infrastructure-as-code for managing Docker Compose stacks across three homelab machines.

> **🚧 BUILD IN PROGRESS - NOT READY FOR DEPLOYMENT**
>
> Building Ansible automation for homelab deployment.
>
> **Current Progress:** Phase 6 - Orchestration Playbooks (next to create)
> **Status:** ✅ Phases 1-4 complete (infrastructure, core services, VPN) | ⏸️ Phase 5 partially complete (deferred) | 🎯 Phase 6 ready to build

## Overview

Modular Ansible-managed infrastructure where each service has its own docker-compose file and services communicate via external Docker networks.

## Machines

- **orac** - 19 total services (13 unique + 6 common)
  - Unique: code-server, portainer, navidrome, metube, it-tools, omni-tools, hugo, chartdb, sshwifty, chromadb, drawio
- **jarvis** - 7 total services (1 unique + 6 common)
  - Unique: homeassistant
- **seraph** - 11 total services (4 unique + 7 common, includes beszel hub)
  - Unique: adguardhome, uptime-kuma, watchyourlan, gocron

**Common services (all machines):** docker-socket-proxy, traefik, beszel-agent, samba, dozzle, whatsupdocker

## Architecture

- **VPN networking**: Tailscale VPN for secure inter-machine communication with MagicDNS and SSH
- **Modular roles**: Each service has its own role with docker-compose configuration
- **Additive-only deployment**: Ansible manages declared services, ignores manual experiments
- **External networks**: Services communicate via Docker networks (`homelab`, `monitoring`)
- **Security**: Docker Socket Proxy for secure container access (no direct socket mounts)
- **HTTPS**: Traefik reverse proxy with automatic Let's Encrypt certificates
- **Monitoring**: Beszel for system and container monitoring
- **Secrets**: Single encrypted vault file (`inventory/group_vars/all/vault.yml`)

## Features

- 🔒 **Encrypted secrets** - ansible-vault with single vault file
- 🐳 **Docker-first** - All services containerized
- 🔄 **Idempotent** - Safe to run multiple times
- 🧪 **Experiment-friendly** - Manual containers coexist peacefully with Ansible-managed services
- 📝 **Well-documented** - Each role has comprehensive README
- 🎯 **Targeted deployments** - Deploy by host, service, or tag
- 🔐 **Secure by default** - Docker Socket Proxy, HTTPS-only, no root

## ⚠️ Current Status

**🚧 BUILD IN PROGRESS - NOT READY FOR DEPLOYMENT**

This project is actively being built. Do not attempt to deploy yet.

**What's complete:**
- ✅ Ansible structure and inventory
- ✅ Core infrastructure roles (tailscale, common, docker, NAS mounts)
- ✅ Core service roles (proxy, traefik, monitoring, file sharing)
- ✅ 2 common application service roles (dozzle, whatsupdocker)
- ✅ Configuration centralization (single source of truth)

**What's remaining:**
- 🎯 Main deployment playbook (`site.yml`) - NEXT
- 🔲 Testing and validation
- 🔲 End-user documentation
- ⏸️ 18 machine-specific application service roles (deferred until after testing)

**When complete, deployment will be:**
```bash
# 1. Generate Beszel keypair
ansible-playbook playbooks/setup-secrets.yml

# 2. Fill secrets in vault
ansible-vault edit inventory/group_vars/all/vault.yml

# 3. Deploy everything
ansible-playbook playbooks/site.yml

# Or deploy to specific host
ansible-playbook playbooks/site.yml --limit orac

# Or deploy specific service
ansible-playbook playbooks/site.yml --tags traefik
```

## Project Structure

```
homelab/
├── ansible.cfg              # Ansible configuration
├── inventory/
│   ├── hosts.yml           # Machine definitions
│   └── group_vars/         # Shared variables and secrets
├── host_vars/              # Per-machine configuration
│   ├── orac/
│   ├── jarvis/
│   └── seraph/
├── roles/                  # Service deployment roles
│   ├── tailscale/         # ✅ VPN networking
│   ├── common/            # ✅ Base system setup
│   ├── docker/            # ✅ Docker + networks
│   ├── nas_mounts/        # ✅ NAS share mounting
│   ├── docker_socket_proxy/ # ✅ Docker API proxy
│   ├── traefik/           # ✅ Reverse proxy
│   ├── beszel/            # ✅ Monitoring hub
│   ├── beszel_agent/      # ✅ Monitoring agent
│   ├── samba/             # ✅ File sharing
│   ├── dozzle/            # ✅ Log viewer
│   ├── whatsupdocker/     # ✅ Update checker
│   └── [18 more services] # 🔲 In progress
├── playbooks/             # Deployment playbooks
│   ├── setup-secrets.yml # Generate Beszel keypair
│   └── site.yml          # 🔲 Main deployment (not yet created)
├── PLAN.md               # Implementation phases
├── CONTINUATION.md       # Current work status
└── CLAUDE.md             # Project context
```

## Documentation

### Project Documentation
- [PLAN.md](PLAN.md) - Detailed implementation phases and progress tracking
- [CONTINUATION.md](CONTINUATION.md) - Current work status and next steps
- [CLAUDE.md](CLAUDE.md) - Project context for AI assistance

### Setup and Deployment Guides
- [docs/setup.md](docs/setup.md) - Initial setup and prerequisites
- [docs/secrets.md](docs/secrets.md) - Secret management with ansible-vault
- [docs/deployment.md](docs/deployment.md) - Deployment workflows and commands
- [docs/configuration.md](docs/configuration.md) - Variable hierarchy and machine configuration
- [docs/adding-services.md](docs/adding-services.md) - Guide for adding new services

### Role Documentation
- [roles/*/README.md](roles/) - Individual role documentation for each service

## Build Status

**Current Phase:** Phase 6 - Orchestration Playbooks (next to create)

### Completed ✅
- **Phase 1:** Security Foundation (single vault, secrets placeholders)
- **Phase 2:** Ansible Structure (inventory, host vars, centralized config)
- **Phase 3:** Core Infrastructure
  - ✅ tailscale (VPN networking with MagicDNS and SSH)
  - ✅ common (base system setup)
  - ✅ docker (container engine + networks)
  - ✅ nas_mounts (systemd-based NFS/CIFS mounting)
- **Phase 4:** Core Services
  - ✅ docker_socket_proxy (secure Docker API access)
  - ✅ traefik (reverse proxy with Let's Encrypt)
  - ✅ beszel + beszel_agent (monitoring)
  - ✅ samba (file sharing)
- **Phase 5:** Application Services (PARTIALLY COMPLETE - 2 common services, 18 machine-specific deferred)
  - ✅ dozzle (log viewer)
  - ✅ whatsupdocker (update checker)
  - ⏸️ 18 machine-specific services deferred until after core infrastructure testing

### Next 🎯
- **Phase 6:** Orchestration Playbooks (site.yml) - READY TO BUILD
- **Phase 7:** Testing & Validation (on jarvis first)
- **Phase 8:** End-User Documentation
- **Phase 9:** Repository Finalization

**Rationale:** We have enough services (10 roles) to validate the entire infrastructure. Remaining application services can be added incrementally after core infrastructure is proven working.

See [PLAN.md](PLAN.md) for detailed phase breakdown and [CONTINUATION.md](CONTINUATION.md) for current work.


