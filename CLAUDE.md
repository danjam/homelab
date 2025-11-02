# Claude Context Document

## Project Overview
Homelab infrastructure using Ansible to deploy Docker Compose stacks across three machines.

## 🚨 CRITICAL REMINDERS

**WE ARE BUILDING AUTOMATION, NOT DEPLOYING**
- Don't ask user to do manual tasks - Ansible automates
- Don't ask user to run playbooks during build phase
- Don't create end-user documentation for internal build phases
- User fills secrets and deploys ONCE when build is complete
- **STOP CREATING UNNECESSARY DOCUMENTATION FILES**

**Research Thoroughly When Uncertain**
- Use Context7, Gemini, web_search, web_fetch
- Combine sources for accuracy

**Current Work**
- See `PLAN.md` for overall progress

---

## Configuration

### Machines
**orac** - 17 services
- code-server, portainer, navidrome, metube, it-tools, omni-tools, hugo, chartdb, sshwifty, chromadb, drawio, dozzle, whatsupdocker
- NAS mounts from 192.168.1.60: /mnt/music, /mnt/roms, /mnt/backups
- Samba: 4 shares (outbox, www, opt, dropbox)

**jarvis** - 7 services  
- homeassistant, dozzle, whatsupdocker
- Samba: 1 share (opt)

**seraph** - 11 services (hosts Beszel hub)
- beszel (hub), adguardhome, uptime-kuma, watchyourlan, gocron, dozzle, whatsupdocker
- Samba: 1 share (opt)

**Common services (all):** docker_socket_proxy, traefik, beszel_agent, samba, dozzle, whatsupdocker

### Settings
- Domain: `dannyjames.net`
- User: `danjam` (puid/pgid: 1000)
- Timezone: `Europe/London`
- Directory: `/opt/homelab/`
- Networks: `homelab` (external), `monitoring` (external)

---

## Deployment Workflow (When Build Complete)

```bash
# 1. Generate secrets (auto-generates Beszel keypair)
ansible-playbook playbooks/setup-secrets.yml

# 2. Fill secrets in vault (ONE FILE)
ansible-vault edit inventory/group_vars/all/vault.yml

# 3. Deploy everything
ansible-playbook playbooks/site.yml

# Deploy to specific machine
ansible-playbook playbooks/site.yml --limit orac

# Deploy specific service
ansible-playbook playbooks/site.yml --tags traefik

# Dry run
ansible-playbook playbooks/site.yml --check --diff
```

---

## Key Points
- Building automation FIRST, deploy ONCE when complete
- Let Ansible automate - don't ask user for manual work
- PLAN.md has progress tracking
- CONTINUATION.md has current work
- Don't create extra documentation files unnecessarily

## Documentation

**Start here:** [README.md](README.md) - Project overview and current status

**Planning & Progress:**
- PLAN.md - Detailed phase-by-phase implementation plan
- CONTINUATION.md - Current work and immediate next steps

**Guides (in docs/):**
- `docs/setup.md` - Initial setup and prerequisites
- `docs/secrets.md` - Secret management workflow
- `docs/deployment.md` - Deployment commands and workflows
- `docs/configuration.md` - Variable hierarchy and machine config
- `docs/adding-services.md` - Adding new service roles

**Note:** All docs have been updated to reflect current architecture (Docker Socket Proxy, single vault, Tailscale networking).
