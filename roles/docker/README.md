# Docker Role

Installs Docker CE, Docker Compose v2 plugin, and creates external Docker networks for homelab infrastructure.

## Overview

This role provides a complete Docker installation and configuration for Ubuntu-based systems, including:
- Docker CE (Community Edition) installation from official repositories
- Docker Compose v2 as a plugin (not standalone)
- Docker daemon configuration (logging, storage driver)
- User group management for Docker access
- External network creation for service communication

## Requirements

- Ubuntu-based system (tested on Ubuntu 22.04 LTS)
- Ansible 2.9 or higher
- `community.docker` collection installed

## Role Variables

### Docker Installation

```yaml
# Docker edition and package state
docker_edition: ce
docker_package_state: present
```

### Docker Daemon Configuration

```yaml
docker_daemon_options:
  log-driver: "json-file"
  log-opts:
    max-size: "10m"
    max-file: "3"
  storage-driver: "overlay2"
```

**Log Driver Options:**
- `json-file`: Default JSON logging driver
- `max-size`: Maximum size of each log file before rotation
- `max-file`: Maximum number of log files to retain

**Storage Driver:**
- `overlay2`: Recommended driver for modern Linux systems

### External Networks

```yaml
docker_networks:
  - name: homelab
    subnet: 172.20.0.0/16
    driver: bridge
  - name: monitoring
    subnet: 172.21.0.0/16
    driver: bridge
```

**Network Configuration:**
- `name`: Network name (must be unique)
- `subnet`: CIDR notation for network subnet
- `driver`: Network driver (typically `bridge`)

### User Management

```yaml
docker_users:
  - "{{ homelab_user }}"
```

Users listed here will be added to the `docker` group, allowing them to run Docker commands without `sudo`.

**Note:** Users may need to log out and back in for group membership to take effect.

## Dependencies

- `common` role (creates base directory structure)

## Example Playbook

```yaml
---
- name: Install Docker on homelab machines
  hosts: homelab
  become: true
  
  roles:
    - role: docker
      tags: ['docker']
```

### Deploy to Specific Machine

```bash
ansible-playbook playbooks/site.yml --limit orac --tags docker
```

### Deploy Only Networks

```bash
ansible-playbook playbooks/site.yml --tags docker-networks
```

## What Gets Installed

### Packages

- `docker-ce`: Docker Engine (Community Edition)
- `docker-ce-cli`: Docker command-line interface
- `containerd.io`: Container runtime
- `docker-compose-plugin`: Docker Compose v2 as a plugin

### Configuration Files

- `/etc/docker/daemon.json`: Docker daemon configuration
- `/etc/apt/sources.list.d/docker.list`: Docker APT repository

### External Networks

- `homelab` (172.20.0.0/16): Primary network for web-accessible services
- `monitoring` (172.21.0.0/16): Network for monitoring services (Beszel, etc.)

## Tags

This role supports the following tags for selective execution:

- `docker`: Apply all Docker tasks
- `docker-install`: Install Docker packages only
- `docker-config`: Configure Docker daemon only
- `docker-users`: Manage docker group membership only
- `docker-service`: Manage Docker service state only
- `docker-networks`: Create external networks only
- `docker-verify`: Verify installation only

### Tag Usage Examples

```bash
# Install Docker only (skip configuration)
ansible-playbook playbooks/site.yml --tags docker-install

# Reconfigure Docker daemon
ansible-playbook playbooks/site.yml --tags docker-config

# Add users to docker group
ansible-playbook playbooks/site.yml --tags docker-users

# Create networks only
ansible-playbook playbooks/site.yml --tags docker-networks
```

## Handlers

### restart docker

Restarts the Docker service and reloads systemd daemon configuration.

**Triggered by:**
- Changes to Docker daemon configuration (`daemon.json`)
- Docker package installation/updates


## Verification

After deployment, verify the installation:

```bash
# Check Docker version
docker --version

# Check Docker Compose plugin
docker compose version

# Verify Docker service is running
systemctl status docker

# List external networks
docker network ls | grep -E 'homelab|monitoring'

# Test Docker without sudo (may require logout/login)
docker ps

# Verify network configuration
docker network inspect homelab
docker network inspect monitoring
```

## Troubleshooting

### Docker commands require sudo

**Problem:** User cannot run Docker commands without sudo.

**Solution:**
```bash
# Verify user is in docker group
groups

# If not, the role will add them. Then logout and login:
exit
# Log back in via SSH

# Verify again
groups
docker ps
```

### Networks already exist

**Problem:** External networks already exist from previous setup.


**Solution:** The role is idempotent and will not recreate existing networks. If you need to recreate:

```bash
# Remove existing networks (ensure no containers are using them)
docker network rm homelab monitoring

# Re-run the role
ansible-playbook playbooks/site.yml --tags docker-networks
```

### Docker service fails to start

**Problem:** Docker service won't start after installation.

**Solution:**
```bash
# Check Docker logs
journalctl -u docker -n 50

# Check daemon configuration
cat /etc/docker/daemon.json

# Validate JSON syntax
python3 -m json.tool /etc/docker/daemon.json

# Restart Docker manually
sudo systemctl restart docker
```

### Repository key errors

**Problem:** GPG key errors when adding Docker repository.

**Solution:**
```bash
# Remove old keys and repository
sudo rm /etc/apt/keyrings/docker.gpg
sudo rm /etc/apt/sources.list.d/docker.list
sudo apt update

# Re-run the role
ansible-playbook playbooks/site.yml --tags docker-install
```


## Network Architecture

### homelab Network (172.20.0.0/16)

Primary network for service communication and Traefik routing.

**Connected Services:**
- Traefik (reverse proxy)
- All web-accessible services (code-server, navidrome, portainer, etc.)
- Services requiring external access

**Purpose:** Allows Traefik to route traffic to backend services.

### monitoring Network (172.21.0.0/16)

Dedicated network for monitoring infrastructure.

**Connected Services:**
- Beszel hub (on seraph)
- Beszel agents (all machines)
- Other monitoring tools (uptime-kuma, dozzle)

**Purpose:** Isolates monitoring traffic from application traffic.

### Why External Networks?

External networks allow services in separate compose files to communicate:

```yaml
# Service A compose file
networks:
  homelab:
    external: true

# Service B compose file  
networks:
  homelab:
    external: true
```

Both services can now communicate via the `homelab` network without being in the same compose file.


## Important Notes

### Docker Compose v2

This role installs Docker Compose as a **plugin**, not the standalone binary.

**Correct usage:**
```bash
docker compose up -d      # ✅ Plugin syntax
docker-compose up -d      # ❌ Old standalone binary
```

### User Group Membership

Adding users to the `docker` group grants full Docker access (equivalent to root).

**Security consideration:** Only add trusted users to the docker group.

### Network Subnet Selection

The subnets `172.20.0.0/16` and `172.21.0.0/16` are chosen to avoid conflicts with:
- Common home networks (192.168.x.x)
- Docker default bridge (172.17.0.0/16)
- Common VPN ranges (10.x.x.x)

If these conflict with your network, modify `docker_networks` in `defaults/main.yml`.

### Daemon Configuration

The daemon configuration enables:
- **Log rotation**: Prevents logs from consuming excessive disk space
- **overlay2 storage**: Modern, efficient storage driver
- **JSON logging**: Structured logs for better parsing

## Idempotency

This role is fully idempotent and safe to run multiple times:

- Docker packages will only be installed if missing
- Configuration changes will trigger a restart only if needed
- Networks will only be created if they don't exist
- Users will only be added to docker group if not already members
- No unnecessary restarts or disruptions

## Files Created

```
/etc/docker/daemon.json              # Docker daemon configuration
/etc/apt/keyrings/docker.gpg         # Docker repository GPG key
/etc/apt/sources.list.d/docker.list  # Docker APT repository
```

## Post-Installation

After this role completes:

1. **Verify installation** with `docker --version` and `docker compose version`
2. **Test network creation** with `docker network ls`
3. **Users may need to logout/login** for docker group membership to take effect
4. **Ready for service deployment** - Traefik and other services can now use external networks

## Related Roles

- `common`: Must run before docker role (creates base directories)
- `docker_socket_proxy`: Requires docker role to be completed first
- `traefik`: Requires docker role and docker_socket_proxy
- All service roles: Require docker role for network connectivity

## License

MIT

## Author

Homelab Infrastructure Project
