# Dozzle Role

Deploys Dozzle, a real-time Docker log viewer with a clean web interface.

## Overview

Dozzle provides a simple, lightweight web UI for viewing Docker container logs in real-time. It connects to the Docker Socket Proxy for secure access to Docker.

## Features

- Real-time log streaming
- Container filtering (only shows running containers by default)
- Clean, responsive web interface
- No authentication required (protected by Traefik)
- Healthcheck enabled
- Integrates with Docker Socket Proxy for security

## Requirements

- Docker and Docker Compose v2
- Docker Socket Proxy role deployed
- Traefik role deployed
- External networks: `homelab`, `{hostname}_docker_socket`

## Role Variables

### Defaults

```yaml
# Docker image
dozzle_image: "amir20/dozzle:latest"

# Paths
dozzle_dir: "{{ homelab_dir }}/dozzle"

# Network
dozzle_network: homelab

# Docker Socket Proxy connection
docker_socket_proxy_endpoint: "tcp://docker-socket-proxy:2375"

# Container restart policy
container_restart_policy: "{{ default_container_restart_policy }}"
```

## Dependencies

This role depends on:
- `docker_socket_proxy` - For secure Docker API access
- `traefik` - For HTTPS reverse proxy

## Example Playbook

```yaml
- hosts: homelab
  become: true
  roles:
    - role: dozzle
      when: "'dozzle' in services"
```

## Deployment

Deploy with tags:

```bash
# Deploy everything
ansible-playbook playbooks/site.yml --tags dozzle

# Setup only
ansible-playbook playbooks/site.yml --tags dozzle-setup

# Config only
ansible-playbook playbooks/site.yml --tags dozzle-config

# Start only
ansible-playbook playbooks/site.yml --tags dozzle-start
```

## Access

After deployment, access Dozzle at:
- `https://dozzle.{hostname}.dannyjames.net`

## Configuration

### Environment Variables

The role configures these environment variables:

- `DOCKER_HOST` - Points to Docker Socket Proxy
- `DOZZLE_LEVEL` - Log level (info)
- `DOZZLE_FILTER` - Only show running containers

### Networks

Dozzle connects to two networks:
- `homelab` - For Traefik access
- `{hostname}_docker_socket` - For Docker Socket Proxy access

## Troubleshooting

### Container not accessible

Check Traefik labels:
```bash
cd /opt/homelab/dozzle
docker compose config
```

### Cannot connect to Docker

Verify Docker Socket Proxy is running:
```bash
docker ps | grep docker-socket-proxy
```

Check network connectivity:
```bash
docker exec dozzle ping docker-socket-proxy
```

### Logs

View Dozzle logs:
```bash
docker logs dozzle
```

## Security Notes

- Dozzle connects via Docker Socket Proxy (not direct socket mount)
- No authentication configured (rely on Traefik for access control)
- Only shows running containers by default
- Read-only access to Docker API

## Tags

- `dozzle` - All tasks
- `dozzle-setup` - Directory creation
- `dozzle-config` - Configuration deployment
- `dozzle-start` - Service start
- `dozzle-verify` - Health check

## License

Part of the homelab infrastructure automation project.
