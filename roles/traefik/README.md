# Traefik Role

Deploys Traefik reverse proxy for automatic HTTPS and service routing.

## Features

- **Automatic HTTPS** via Let's Encrypt with Cloudflare DNS challenge
- **Wildcard certificates** for `*.dannyjames.net` and `*.{machine}.dannyjames.net`
- **Dashboard** accessible at `traefik.{machine}.dannyjames.net`
- **TLS 1.2/1.3** with modern security settings
- **Docker Socket Proxy integration** for secure Docker API access
- **Log management** with configurable log levels

## Architecture

```
Docker Container
    └─> Traefik
        └─> tcp://docker-socket-proxy:2375 (via docker_socket_proxy role)
            └─> /var/run/docker.sock (read-only)
```

Traefik connects to Docker Socket Proxy (deployed separately) for secure Docker API access.

## Requirements

### Ansible Collections
- `community.docker`

### Dependencies

This role **requires** the `docker_socket_proxy` role to be deployed first:

```yaml
roles:
  - role: docker_socket_proxy
  - role: traefik
```

### Variables Required

**In `inventory/group_vars/all/vars.yml`:**
```yaml
domain_root: dannyjames.net
homelab_dir: /opt/homelab
docker_user: danjam
```

**In `host_vars/{machine}/vars.yml`:**
```yaml
hostname: orac  # or jarvis, seraph
subdomain: orac  # or jarvis, seraph
domain: "{{ subdomain }}.{{ domain_root }}"
```

**In `inventory/group_vars/all/vault.yml` (encrypted):**
```yaml
vault_cloudflare_email: "your-email@example.com"
vault_cloudflare_dns_token: "your-cloudflare-api-token"
```

### Docker Networks

The role expects these networks to exist:
- `homelab` - Main network for all services (created by `docker` role)
- `{hostname}_docker_socket` - Docker Socket Proxy network (created by `docker_socket_proxy` role)

## Directory Structure

Creates the following structure on the target machine:

```
/opt/homelab/
├── traefik/
│   └── docker-compose.yml
├── config/
│   └── traefik/
│       ├── traefik.yml      # Static configuration
│       └── dynamic.yaml     # Dynamic configuration (TLS settings)
├── data/
│   └── traefik/
│       └── certs/
│           └── acme.json    # Let's Encrypt certificates
├── logs/
│   └── traefik/
│       └── traefik.log      # Traefik logs
└── secrets/
    ├── cloudflare_email     # Cloudflare email (Docker secret)
    └── cloudflare_dns_token  # Cloudflare API token (Docker secret)
```

## Usage

### Deploy Traefik to all machines
```bash
# Deploy dependencies first
ansible-playbook playbooks/site.yml --tags docker-socket-proxy

# Then deploy Traefik
ansible-playbook playbooks/site.yml --tags traefik
```

### Deploy to specific machine
```bash
ansible-playbook playbooks/site.yml --tags docker-socket-proxy,traefik --limit orac
```

### Check what would change
```bash
ansible-playbook playbooks/site.yml --tags traefik --check --diff
```

## Adding Services to Traefik

Services can be auto-discovered by Traefik using Docker labels:

```yaml
services:
  myservice:
    image: myservice:latest
    networks:
      - homelab  # Must be on homelab network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myservice.{{ domain }}`)"
      - "traefik.http.routers.myservice.entrypoints=websecure"
      - "traefik.http.routers.myservice.tls=true"
      - "traefik.http.routers.myservice.tls.certresolver=letsencrypt"
      - "traefik.http.services.myservice.loadbalancer.server.port=8080"

networks:
  homelab:
    external: true
```

## Configuration

### Default Variables

See `defaults/main.yml` for all configurable variables. Key settings:

- `traefik_image`: Traefik Docker image (default: `traefik:latest`)
- `traefik_log_level`: Log level (default: `INFO`)
- `traefik_dashboard_enabled`: Enable dashboard (default: `true`)
- `traefik_cert_resolver`: Certificate resolver name (default: `letsencrypt`)
- `traefik_acme_server`: ACME server URL (production by default)
- `docker_socket_proxy_endpoint`: Endpoint for Docker Socket Proxy

### Switching to Staging

For testing, use Let's Encrypt staging to avoid rate limits:

```yaml
# In host_vars or group_vars
traefik_acme_server: "https://acme-staging-v02.api.letsencrypt.org/directory"
```

**Note:** Staging certificates will show as untrusted in browsers but work for testing.

## Troubleshooting

### Check Traefik logs
```bash
ssh danjam@orac
docker logs traefik
# or
cat /opt/homelab/logs/traefik/traefik.log
```

### Verify Docker Socket Proxy connection
```bash
# Check docker-socket-proxy is running
docker ps | grep docker-socket-proxy

# Test from Traefik container
docker exec traefik wget -qO- http://docker-socket-proxy:2375/containers/json
```

### Check certificate status
```bash
docker exec traefik cat /certs/acme.json | jq
```

### Verify services are discovered
Access the Traefik dashboard at `https://traefik.{machine}.dannyjames.net`

### Common Issues

**Certificate not generated:**
- Check Cloudflare credentials are correct
- Verify DNS is pointing to your server
- Check Traefik logs for ACME errors
- Ensure firewall allows outbound port 53 (DNS)

**Services not appearing:**
- Ensure service has `traefik.enable=true` label
- Verify service is on `homelab` network
- Check docker-socket-proxy is running
- Restart Traefik: `cd /opt/homelab/traefik && docker compose restart`

**Cannot connect to docker-socket-proxy:**
- Ensure `docker_socket_proxy` role ran successfully
- Check network exists: `docker network ls | grep docker_socket`
- Verify Traefik is on the `{hostname}_docker_socket` network

## Security

### Docker Socket Protection
Traefik connects to Docker Socket Proxy (separate role) which limits access to the Docker API. By default, Docker Socket Proxy only allows container listing.

See `roles/docker_socket_proxy/README.md` for details on permissions and security.

### Secrets Management
- Cloudflare credentials stored as Docker secrets (not environment variables)
- Secret files have `0600` permissions
- Secrets directory has `0700` permissions
- Secrets are deployed from encrypted ansible-vault

### TLS Configuration
- Minimum TLS 1.2
- Maximum TLS 1.3
- SNI strict mode enabled
- HTTPS only (no port 80)

## Dependencies

This role should be deployed after:
1. `common` role (creates base directories)
2. `docker` role (installs Docker, creates `homelab` network)
3. **`docker_socket_proxy` role** (provides secure Docker API access)

## Role Deployment Order

```yaml
# In playbooks/site.yml
roles:
  - role: common
  - role: docker
  - role: docker_socket_proxy  # Must come before Traefik
  - role: traefik              # Depends on docker_socket_proxy
```

## Notes

- HTTPS only - port 80 is **not** exposed
- Uses Cloudflare DNS challenge (no need to expose any ports for ACME)
- Wildcard certificates reduce Let's Encrypt API calls
- Dashboard is secured behind HTTPS
- Logs rotate automatically via Docker logging driver
- Traefik requires docker-socket-proxy to function
