# Continuation: Next Steps

## 🔄 Phase 3: Core Infrastructure - MOSTLY COMPLETE

Foundational infrastructure roles status:
- Phase 3.0: Tailscale (VPN networking) - 🔲 NOT STARTED
- Phase 3.1: Common (system setup) - ✅ COMPLETE
- Phase 3.2: Docker (container engine + networks) - ✅ COMPLETE
- Phase 3.3: NAS Mounts (storage, 3 shares on orac, 1 on jarvis/seraph) - ✅ COMPLETE

## ✅ Phase 4: Core Services - COMPLETE

All core service roles complete:
- docker_socket_proxy
- traefik
- beszel (hub)
- beszel_agent
- samba

---

## 🔄 Phase 5: Application Services - IN PROGRESS

**Goal:** Create roles for 18+ application services

### ✅ Common Services (2/2 COMPLETE)
- ✅ dozzle (log viewer) - COMPLETE
- ✅ whatsupdocker (update checker) - COMPLETE

### Service Categories

**Common (all machines):**
- ✅ dozzle (log viewer) - COMPLETE
- ✅ whatsupdocker (update checker) - COMPLETE

**orac (13 unique services):**
- code-server
- portainer
- navidrome
- metube
- it-tools
- omni-tools
- hugo
- chartdb
- sshwifty
- chromadb
- drawio

**jarvis (1 unique service):**
- homeassistant

**seraph (4 unique services):**
- adguardhome
- uptime-kuma
- watchyourlan
- gocron

### Build Order

1. Next: Tailscale role (Phase 3.0) - VPN networking layer
2. ✅ Common services (dozzle, whatsupdocker) - COMPLETE
3. Then: Machine-specific services by complexity:
   - Simple web services first (portainer, it-tools, omni-tools, hugo, etc.)
   - Services with dependencies last (homeassistant, adguardhome, navidrome)

### After Phase 5

- Phase 6: Orchestration playbooks (site.yml)
- Phase 7: Testing
- Phase 8: Documentation
- Phase 9: Repository prep
