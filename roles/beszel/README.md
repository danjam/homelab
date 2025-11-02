# Beszel Hub Role

Deploys the Beszel monitoring hub that collects and displays metrics from Beszel agents across your infrastructure.

## Features

- **Centralized Monitoring**: Collects metrics from all Beszel agents
- **Web Dashboard**: Clean web interface for viewing system metrics
- **Automatic HTTPS**: Integrated with Traefik for secure access
- **Persistent Storage**: Metrics data stored in Docker volumes
- **Multi-Agent Support**: Monitors multiple systems simultaneously
- **Real-time Updates**: Live metric updates from all agents
- **Docker Integration**: Monitors container metrics via agents

## Requirements

- Docker and Docker Compose installed on target host
- Traefik reverse proxy (deployed via `traefik` role)
- Homelab network available
- Domain name configured for web access
- Beszel agents deployed on monitored hosts

## Dependencies

- Requires Traefik for HTTPS access (optional but recommended)
- Works with `beszel_agent` role for monitoring agents

## Role Variables

### Required Variables

```yaml
# From inventory variables
domain_root: dannyjames.net
```

### Optional Variables (defaults/main.yml)

```yaml
# Docker image configuration
beszel_image: henrygd/beszel
beszel_image_tag: latest

# Hub web interface port (internal)
beszel_port: 8090

# Domain for web access
beszel_domain: "beszel.{{ domain_root }}"

# Base directory for homelab services
beszel_base_dir: /opt/homelab
beszel_data_dir: "{{ beszel_base_dir }}/data/beszel"

# Docker network (must match Traefik)
beszel_network: homelab

# Traefik integration
beszel_enable_traefik: true
beszel_traefik_entrypoint: websecure
beszel_traefik_certresolver: letsencrypt

# Optional: Disable password authentication
# beszel_disable_password_auth: false

# Additional environment variables
beszel_extra_env: {}
```
