# What's Up Docker (WUD) Role

Deploys What's Up Docker, a tool for monitoring Docker container image updates.

## Overview

What's Up Docker (WUD) monitors your Docker containers and notifies you when new versions of their images are available. It provides a web dashboard showing update status for all monitored containers.

## Features

- Automatic monitoring of Docker containers
- Configurable check schedule (default: every 6 hours)
- Web dashboard for viewing update status
- Connects to Docker Socket Proxy for security
- Event-based monitoring for real-time updates
- Healthcheck enabled

## Requirements

- Docker and Docker Compose v2
- Docker Socket Proxy role deployed
- Traefik role deployed
- External networks: `homelab`, `{hostname}_docker_socket`

## Role Variables

### Defaults

```yaml
# Docker image
whatsupdocker_image: "getwud/wud:latest"

# Paths
whatsupdocker_dir: "{{ homelab_dir }}/whatsupdocker"

# Network
whatsupdocker_network: homelab

# Docker Socket Proxy connection
docker_socket_proxy_endpoint: "tcp://docker-socket-proxy:2375"

# Watcher configuration
whatsupdocker_cron: "0 */6 * * *"  # Every 6 hours
whatsupdocker_watchbydefault: true
whatsupdocker_watchevents: true

# Container restart policy
container_restart_policy: "{{ default_container_restart_policy }}"
```

### Host Variables

Override in host_vars if needed:

```yaml
# Check more frequently
whatsupdocker_cron: "0 */3 * * *"  # Every 3 hours

# Disable default watching (use container labels instead)
whatsupdocker_watchbydefault: false
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
    - role: whatsupdocker
      when: "'whatsupdocker' in services"
```

## Deployment

Deploy with tags:

```bash
# Deploy everything
ansible-playbook playbooks/site.yml --tags whatsupdocker

# Setup only
ansible-playbook playbooks/site.yml --tags whatsupdocker-setup

# Config only
ansible-playbook playbooks/site.yml --tags whatsupdocker-config

# Start only
ansible-playbook playbooks/site.yml --tags whatsupdocker-start
```

## Access

After deployment, access WUD at:
- `https://wud.{hostname}.dannyjames.net`

## Configuration

### Environment Variables

The role configures these environment variables:

- `WUD_WATCHER_LOCAL_HOST` - Docker Socket Proxy hostname
- `WUD_WATCHER_LOCAL_PORT` - Docker Socket Proxy port (2375)
- `WUD_WATCHER_LOCAL_CRON` - Update check schedule
- `WUD_WATCHER_LOCAL_WATCHBYDEFAULT` - Watch all containers by default
- `WUD_WATCHER_LOCAL_WATCHEVENTS` - Enable real-time event monitoring

### Networks

WUD connects to two networks:
- `homelab` - For Traefik access
- `{hostname}_docker_socket` - For Docker Socket Proxy access

### Container Labels

To exclude a container from monitoring, add this label:

```yaml
labels:
  - "wud.watch=false"
```

To monitor only specific containers, set `whatsupdocker_watchbydefault: false` and add:

```yaml
labels:
  - "wud.watch=true"
```

## Scheduling

The default check schedule is every 6 hours. Adjust using CRON syntax:

- `0 */3 * * *` - Every 3 hours
- `0 0 * * *` - Daily at midnight
- `0 0 * * 0` - Weekly on Sunday

## Troubleshooting

### Container not accessible

Check Traefik labels:
```bash
cd /opt/homelab/whatsupdocker
docker compose config
```

### Not detecting updates

Check WUD logs:
```bash
docker logs whatsupdocker
```

Verify Docker Socket Proxy connectivity:
```bash
docker exec whatsupdocker ping docker-socket-proxy
```

### Manually trigger update check

WUD checks on schedule, but you can restart to force check:
```bash
cd /opt/homelab/whatsupdocker
docker compose restart
```

## API Access

WUD provides an API at:
- `https://wud.{hostname}.dannyjames.net/api/watchers`
- `https://wud.{hostname}.dannyjames.net/api/containers`

## Security Notes

- Connects via Docker Socket Proxy (not direct socket mount)
- Read-only access to Docker API
- No authentication configured (rely on Traefik for access control)
- Monitors only containers on local host by default

## Advanced Configuration

### Multiple Hosts

To monitor multiple Docker hosts, add additional watchers in host_vars:

```yaml
whatsupdocker_extra_watchers:
  - name: REMOTEHOST1
    host: remotehost1.example.com
    port: 2375
```

### Triggers/Notifications

WUD supports various notification triggers (webhook, email, etc.). Configure via additional environment variables if needed.

## Tags

- `whatsupdocker` - All tasks
- `whatsupdocker-setup` - Directory creation
- `whatsupdocker-config` - Configuration deployment
- `whatsupdocker-start` - Service start
- `whatsupdocker-verify` - Health check

## License

Part of the homelab infrastructure automation project.
