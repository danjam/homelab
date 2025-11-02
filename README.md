# Homelab Infrastructure

Ansible-based infrastructure-as-code for managing Docker Compose stacks across three homelab machines.

> **🚧 BUILD IN PROGRESS**
> 
> Building Ansible automation for homelab deployment. Not ready for production use.
> 
> **Current Status:** 🟡 Core infrastructure complete, building application services

## Overview

Modular Ansible-managed infrastructure where each service has its own docker-compose file and services communicate via external Docker networks.

## Machines

- **orac** - 17 services (code-server, portainer, navidrome, etc.)
- **jarvis** - 7 services (homeassistant, etc.)
- **seraph** - 11 services (hosts Beszel hub, adguardhome, etc.)

All machines run common services: traefik, docker-socket-proxy, beszel-agent, samba, dozzle, whatsupdocker

## Features

- 🔒 **Encrypted secrets** - All sensitive data encrypted with ansible-vault
- 🐳 **Docker-first** - Everything runs in containers
- 🔄 **Reproducible** - Destroy and rebuild anytime
- 📝 **Well-documented** - Comprehensive guides included
- 🎯 **Targeted deployments** - Deploy specific services to specific machines
- 🛠️ **Helper scripts** - Simplify common tasks

## ⚠️ Before You Start

**Building automation, not deploying yet.** Secrets are filled at deployment time.

Once build is complete:
1. Run `ansible-playbook playbooks/setup-secrets.yml` to generate keys
2. Fill secrets in `inventory/group_vars/all/vault.yml`
3. Deploy with `ansible-playbook playbooks/site.yml`

## Project Structure

```
homelab/
├── ansible.cfg              # Ansible configuration
├── inventory/
│   ├── hosts.yml           # Machine definitions
│   └── group_vars/         # Shared variables and secrets
├── host_vars/              # Per-machine configuration
│   ├── machine1/
│   ├── machine2/
│   └── machine3/
├── roles/                  # Service deployment roles
│   ├── common/            # ✅ Base system setup
│   ├── docker/            # ✅ Docker + networks
│   ├── nas_mounts/        # ✅ NAS share mounting
│   ├── docker_socket_proxy/ # ✅ Docker API proxy
│   ├── traefik/           # ✅ Reverse proxy
│   ├── beszel/            # ✅ Monitoring hub
│   ├── beszel_agent/      # ✅ Monitoring agent
│   └── samba/             # ✅ File sharing
├── playbooks/             # Deployment playbooks
├── scripts/               # Helper scripts
└── docs/                  # Documentation
```

## Documentation

- [PLAN.md](PLAN.md) - Implementation phases and progress
- [CLAUDE.md](CLAUDE.md) - Context document for AI assistance

## Build Status

**Current Phase:** Phase 5 - Application Services

### Completed ✅
- Phase 1: Security Foundation (single vault, secrets placeholders)
- Phase 2: Ansible Structure (inventory, host vars)
- Phase 3: Core Infrastructure (common, docker, nas_mounts)
- Phase 4: Core Services (docker_socket_proxy, traefik, beszel, samba)

### In Progress 🟡
- Phase 5: Application Services (18+ service roles)

### Not Started 🔴
- Phase 6: Orchestration Playbooks
- Phase 7: Testing
- Phase 8: Documentation
- Phase 9: Repository Prep

See [PLAN.md](PLAN.md) for detailed phase breakdown.


