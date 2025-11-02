# Docker Socket Proxy Role

Deploys Docker Socket Proxy as a security layer for Docker socket access. This allows services like Traefik, Portainer, WhatUpDocker, and Dozzle to access the Docker API without directly mounting the Docker socket.

## Purpose

The Docker socket (`/var/run/docker.sock`) provides root-level access to the Docker daemon. Mounting it directly into containers is a security risk. Docker Socket Proxy acts as a firewall, allowing only specific API endpoints to be accessed.

## Features

- **Security Layer** - Filters Docker API access
- **Granular Permissions** - Enable only needed API endpoints
- **Isolated Network** - Runs on per-machine internal network
- **Read-Only Socket** - Docker socket mounted as read-only
- **No External Exposure** - Only accessible within Docker networks

## Architecture

```
Service (Traefik, Portainer, etc.)
    └─> tcp://docker-socket-proxy:2375
        └─> Docker Socket Proxy
            └─> /var/run/docker.sock (read-only)
```

## Requirements

### Ansible Collections
- `community.docker`

### Variables Required

**In `inventory/group_vars/all/vars.yml`:**
```yaml
homelab_dir: /opt/homelab
docker_user: danjam
```

**In `host_vars/{machine}/vars.yml`:**
```yaml
hostname: orac  # or jarvis, seraph
```

## Network Configuration

Creates a machine-specific internal network:
- **Network Name**: `{hostname}_docker_socket` (e.g., `orac_docker_socket`)
- **Driver**: bridge
- **Scope**: Internal to machine

Services needing Docker access must join this network.

## Directory Structure

Creates the following on target machines:

```
/opt/homelab/
└── docker-socket-proxy/
    └── docker-compose.yml
```

## Default Permissions

By default, only `CONTAINERS=1` is enabled. All other APIs are disabled for security.

**Enabled:**
- Container listing and inspection

**Disabled:**
- Image management
- Network management
- Volume management
- Service/Swarm operations
- Container creation/deletion
- Command execution

## Usage

### Deploy to All Machines
```bash
ansible-playbook playbooks/site.yml --tags docker-socket-proxy
```

### Deploy to Specific Machine
```bash
ansible-playbook playbooks/site.yml --tags docker-socket-proxy --limit orac
```

### Enable Additional Permissions

To enable more APIs, override in host_vars or group_vars:

```yaml
# host_vars/orac/vars.yml
# For Portainer (needs more permissions)
docker_socket_proxy_images: 1
docker_socket_proxy_networks: 1
docker_socket_proxy_volumes: 1
docker_socket_proxy_info: 1
docker_socket_proxy_version: 1
```

## Connecting Services

Services connect to the proxy instead of the Docker socket:

### Example: Traefik

```yaml
services:
  traefik:
    networks:
      - web
      - orac_docker_socket  # Join proxy network
    environment:
      # Don't need docker socket
    # volumes:
    #   - /var/run/docker.sock:/var/run/docker.sock  # ❌ Don't do this

networks:
  orac_docker_socket:
    external: true
```

**In traefik.yml:**
```yaml
providers:
  docker:
    endpoint: "tcp://docker-socket-proxy:2375"
```

### Example: Portainer

```yaml
services:
  portainer:
    networks:
      - web
      - orac_docker_socket
    # No socket mount needed

networks:
  orac_docker_socket:
    external: true
```

**Connect Portainer to:** `docker-socket-proxy:2375`

### Example: WhatUpDocker

```yaml
services:
  whatsupdocker:
    networks:
      - orac_docker_socket
    environment:
      WUD_WATCHER_DOCKER_SOCKET: tcp://docker-socket-proxy:2375
```

## Security Considerations

### What It Protects Against

- **Container Escape** - Even if service is compromised, limited API access
- **Privilege Escalation** - Cannot create privileged containers
- **Resource Manipulation** - Cannot delete/modify critical resources
- **System Access** - Cannot execute commands in other containers

### What To Enable

**For Traefik (minimal):**
- `CONTAINERS: 1` only

**For Portainer (management):**
- `CONTAINERS: 1`
- `IMAGES: 1`
- `NETWORKS: 1`
- `VOLUMES: 1`
- `INFO: 1`
- `VERSION: 1`

**For WhatUpDocker (update checker):**
- `CONTAINERS: 1`
- `IMAGES: 1`

### What NOT To Enable

Unless absolutely necessary, avoid:
- `POST: 1` - Allows container/image creation
- `EXEC: 1` - Allows command execution
- `COMMIT: 1` - Allows container commits
- `BUILD: 1` - Allows image builds

## Troubleshooting

### Check if proxy is running
```bash
docker ps | grep docker-socket-proxy
```

### Test proxy connectivity
```bash
# From inside a container on the same network
wget -qO- http://docker-socket-proxy:2375/containers/json
```

### Check logs
```bash
docker logs docker-socket-proxy
```

### Verify network
```bash
docker network ls | grep docker_socket
docker network inspect orac_docker_socket
```

### Common Issues

**Service can't connect to proxy:**
- Ensure service is on the `{hostname}_docker_socket` network
- Check proxy is running
- Verify endpoint URL: `tcp://docker-socket-proxy:2375`

**Permission denied errors:**
- Enable required API in role defaults/vars
- Check proxy logs for denied requests
- Redeploy after changing permissions

**Network not found:**
- Ensure docker_socket_proxy role ran successfully
- Check network was created: `docker network ls`
- Network name should be `{hostname}_docker_socket`

## Dependencies

This role should be deployed:
1. **After** `docker` role (requires Docker installed)
2. **Before** services that need Docker access (Traefik, Portainer, etc.)

## Advanced Configuration

### Custom Network Name

```yaml
# Override default network name
docker_socket_proxy_network: "custom_docker_proxy"
```

### Different Port

```yaml
# Use different internal port
docker_socket_proxy_port: 2376
```

### Additional Environment Variables

```yaml
# In host_vars or role defaults
docker_socket_proxy_log_level: "info"
```

## Best Practices

1. **Minimal Permissions** - Only enable APIs actually needed
2. **Per-Service Review** - Evaluate what each service truly requires
3. **Network Isolation** - Keep proxy network separate from application networks
4. **Monitor Access** - Check proxy logs for unusual activity
5. **Regular Updates** - Keep proxy image updated

## Example Deployment Order

```bash
# 1. Deploy Docker Socket Proxy first
ansible-playbook playbooks/site.yml --tags docker-socket-proxy

# 2. Then deploy services that use it
ansible-playbook playbooks/site.yml --tags traefik
ansible-playbook playbooks/site.yml --tags portainer
ansible-playbook playbooks/site.yml --tags whatsupdocker
```

## Notes

- One proxy per machine
- All services on same machine share the proxy
- Network is internal - not exposed outside Docker
- Proxy itself has no authentication (network isolation provides security)
- Read-only socket mount prevents write operations at OS level
