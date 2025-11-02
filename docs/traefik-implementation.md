# Traefik Role Implementation Summary

## What Was Implemented

Based on the actual Traefik setup found on orac (`/opt/homelab/`), I've created a complete, generic Traefik role that can be deployed to all three machines (orac, jarvis, seraph).

### Files Created

```
roles/traefik/
├── README.md                          # Comprehensive documentation
├── defaults/
│   └── main.yml                       # Default variables
├── handlers/
│   └── main.yml                       # Service restart handler
├── tasks/
│   └── main.yml                       # Main deployment tasks
└── templates/
    ├── docker-compose.yml.j2          # Docker Compose with both services
    ├── traefik.yml.j2                 # Traefik static configuration
    └── dynamic.yaml.j2                # Traefik dynamic configuration (TLS)
```

## Key Features Implemented

### 1. Docker Socket Proxy Integration
✅ Matches current setup exactly
- Deploys `docker-socket-proxy` alongside Traefik
- Traefik connects via `tcp://docker-socket-proxy:2375`
- Security: only exposes container listing capability (`CONTAINERS=1`)
- No direct Docker socket access for Traefik

### 2. Docker Secrets for Cloudflare
✅ Matches current setup exactly
- Cloudflare email and DNS token stored as Docker secrets
- Files created from ansible-vault variables
- Proper permissions (0600 for secrets, 0700 for directory)
- Environment variables reference secret files:
  - `CF_API_EMAIL_FILE=/run/secrets/cloudflare_email`
  - `CF_DNS_API_TOKEN_FILE=/run/secrets/cloudflare_dns_token`

### 3. External Configuration Files
✅ Matches current setup exactly  
- `traefik.yml` - Static configuration
- `dynamic.yaml` - Dynamic configuration (TLS settings)
- Stored in `/opt/homelab/config/traefik/`
- Mounted as read-only into container

### 4. HTTPS Only
✅ Matches current setup exactly
- Only port 443 exposed
- No port 80 (no HTTP)
- TLS 1.2 minimum, TLS 1.3 maximum
- SNI strict mode enabled

### 5. Certificate Management
✅ Matches current setup exactly
- Let's Encrypt with Cloudflare DNS challenge
- Wildcard certificates for `*.dannyjames.net` and `*.{machine}.dannyjames.net`
- Certificates stored in `/opt/homelab/data/traefik/certs/acme.json`
- Production ACME server by default
- Easy switch to staging for testing

### 6. Logging
✅ Matches current setup exactly
- Logs to `/opt/homelab/logs/traefik/traefik.log`
- Configurable log level (default: INFO)
- Access logs disabled by default (can be enabled)

### 7. Network Configuration
✅ Uses existing network
- Uses `homelab` network (not `web` as in plan.md)
- Network must be created externally (by docker role)
- All services must join this network to be proxied

### 8. Traefik Dashboard
✅ Enabled with HTTPS
- Accessible at `traefik.{machine}.dannyjames.net`
- Secured behind HTTPS
- Not insecure mode (no plain HTTP access)

## Generic Design for All Machines

### Variables Used for Genericity

**Machine-specific (from `host_vars/{machine}/vars.yml`):**
```yaml
subdomain: orac  # or jarvis, seraph
domain: "{{ subdomain }}.{{ domain_root }}"
```

**Global (from `inventory/group_vars/all/vars.yml`):**
```yaml
domain_root: dannyjames.net
homelab_dir: /opt/homelab
docker_user: danjam
```

**Secrets (from `inventory/group_vars/all/vault.yml`):**
```yaml
vault_cloudflare_email: "d.s.james@gmail.com"
vault_cloudflare_dns_token: "actual-token"
```

### Wildcard Certificate Generation

The role automatically generates wildcard certificates for **all machines** in the inventory:

```yaml
domains:
  - main: dannyjames.net
    sans:
      - '*.orac.dannyjames.net'
      - '*.jarvis.dannyjames.net'
      - '*.seraph.dannyjames.net'
      - '*.dannyjames.net'
```

This is done dynamically by looping through `groups['homelab']`.

## Differences from Plan.md

### Changed Based on Actual Implementation

1. **Network Name:** Uses `homelab` not `web`
   - Current setup uses single `homelab` network
   - Not separating into web/monitoring networks yet

2. **Port 80:** Not exposed
   - Current setup is HTTPS-only
   - No HTTP to HTTPS redirect (no port 80)

3. **Secrets Location:** `/opt/homelab/secrets/`
   - Not a subdirectory of `/opt/homelab/traefik/`
   - Shared secrets directory for all services

4. **Config Location:** `/opt/homelab/config/traefik/`
   - Not inside traefik directory
   - Follows current structure

## Requirements for Deployment

### Prerequisites

1. **Ansible Collections:**
   ```bash
   ansible-galaxy collection install community.docker
   ```

2. **Docker Role Must Run First:**
   - Installs Docker
   - Creates `homelab` network
   - Sets up Docker daemon

3. **Common Role Should Run First:**
   - Creates base `/opt/homelab` directory
   - Sets proper ownership

4. **Variables Must Be Set:**
   - `domain_root` in group_vars
   - `subdomain` and `domain` in each host_vars
   - `vault_cloudflare_email` and `vault_cloudflare_dns_token` in vault

### Vault Variables Needed

**In `inventory/group_vars/all/vault.yml`** (must be encrypted):
```yaml
vault_cloudflare_email: "d.s.james@gmail.com"
vault_cloudflare_dns_token: "your-actual-token-here"
```

Encrypt with:
```bash
ansible-vault encrypt inventory/group_vars/all/vault.yml
```

## Deployment Commands

### Deploy to All Machines
```bash
ansible-playbook playbooks/site.yml --tags traefik
```

### Deploy to Specific Machine
```bash
ansible-playbook playbooks/site.yml --tags traefik --limit orac
```

### Test Before Deploying
```bash
ansible-playbook playbooks/site.yml --tags traefik --check --diff
```

## Next Steps

### To Complete Migration

1. **Create/Update Variable Files:**
   - Set `domain_root: dannyjames.net` in `inventory/group_vars/all/vars.yml`
   - Ensure each host_vars has `subdomain` and `domain` set

2. **Create Encrypted Vault:**
   ```bash
   # Create vault file
   cat > inventory/group_vars/all/vault.yml << 'EOF'
   ---
   vault_cloudflare_email: "d.s.james@gmail.com"
   vault_cloudflare_dns_token: "your-actual-token"
   EOF
   
   # Encrypt it
   ansible-vault encrypt inventory/group_vars/all/vault.yml
   ```

3. **Ensure Docker Network Exists:**
   The `docker` role should create the `homelab` network:
   ```yaml
   - name: Create homelab Docker network
     community.docker.docker_network:
       name: homelab
       driver: bridge
   ```

4. **Test Deployment:**
   ```bash
   # Test on one machine first
   ansible-playbook playbooks/site.yml --tags traefik --limit jarvis --check
   
   # If check looks good, deploy
   ansible-playbook playbooks/site.yml --tags traefik --limit jarvis
   ```

5. **Verify Services:**
   ```bash
   ssh danjam@jarvis
   cd /opt/homelab/traefik
   docker compose ps
   docker logs traefik
   docker logs docker-socket-proxy
   ```

6. **Access Dashboard:**
   Open `https://traefik.jarvis.dannyjames.net` in browser

## Important Notes

### Security
- ✅ Docker socket protected via socket-proxy
- ✅ Secrets stored as Docker secrets (not env vars)
- ✅ TLS 1.2+ only
- ✅ No insecure dashboard access
- ✅ SNI strict mode

### Idempotency
- ✅ Role can be run multiple times safely
- ✅ Only restarts Traefik if config changes
- ✅ Secrets only updated if changed

### Compatibility
- ✅ Matches existing orac setup exactly
- ✅ Generic enough for all three machines
- ✅ No machine-specific hardcoding
- ✅ Easy to add fourth machine later

## Testing Checklist

Before considering this complete, test:

- [ ] Deploy to jarvis (simplest machine)
- [ ] Verify Traefik dashboard accessible
- [ ] Verify docker-socket-proxy running
- [ ] Add a test service with Traefik labels
- [ ] Verify service accessible via HTTPS
- [ ] Check certificate is valid (not self-signed)
- [ ] Verify logs are being written
- [ ] Test config change triggers restart
- [ ] Deploy to orac
- [ ] Deploy to seraph
- [ ] Verify all three dashboards accessible

## Known Limitations

1. **Port 80 Not Available:**
   - Cannot redirect HTTP to HTTPS
   - Services must use HTTPS URLs directly
   - This matches current setup

2. **Single Network:**
   - All services share `homelab` network
   - Not isolated into web/monitoring/internal
   - Could be improved later

3. **Certificate Rate Limits:**
   - Let's Encrypt has rate limits
   - Use staging for testing
   - Production: 50 certs per domain per week

## Troubleshooting

### Check if role files are correct
```bash
cd ~/Projects/homelab/roles/traefik
find . -type f | sort
```

### Validate templates
```bash
# Check syntax
ansible-playbook playbooks/site.yml --tags traefik --syntax-check

# See what would be deployed
ansible-playbook playbooks/site.yml --tags traefik --limit orac --check --diff
```

### Common Issues

**"vault_cloudflare_email" is undefined:**
- Vault file not created or not encrypted
- Variable name mismatch
- Vault password incorrect

**"homelab network not found":**
- Docker role hasn't run yet
- Network wasn't created
- Run: `docker network create homelab` manually

**Traefik won't start:**
- Check logs: `docker logs traefik`
- Verify socket-proxy is running
- Check config file syntax

## Summary

✅ **Complete Traefik role implemented**
- Matches current production setup on orac
- Generic for all three machines
- Includes docker-socket-proxy for security
- Uses Docker secrets for credentials
- Comprehensive documentation
- Ready for deployment

🎯 **Ready to test on jarvis first, then rollout to all machines**
