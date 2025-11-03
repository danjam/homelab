# Samba Role

Ansible role to deploy Samba file sharing server using Docker Compose.

## Requirements

- Docker and Docker Compose V2 installed
- `community.docker` Ansible collection

## Role Variables

### Required Variables

- `samba_shares`: List of shares to configure. Each share must have:
  - `local_path`: Path on the host to share
  - `share_name`: Name of the share
  - `browseable`: (optional) Whether share is browseable, default varies by share
  - `writable`: (optional) Whether share is writable, default is `true`

### Optional Variables

- `samba_service_dir`: Directory for Samba service files (default: `{{ homelab_dir }}/samba`)
- `samba_image`: Docker image to use (default: `ghcr.io/servercontainers/samba:latest`)
- `samba_restart_policy`: Container restart policy (default: `unless-stopped`)
- `samba_port`: Samba port on host (default: `445`)
- `samba_global_stanza`: Global Samba configuration

## Dependencies

Uses these group variables:
- `homelab_dir`: Base directory for homelab services
- `docker_user`: User to own service files
- `default_username`: Username for Samba authentication
- `default_password`: Password for Samba authentication (should be in vault)
- `puid`: User ID for container
- `default_container_restart_policy`: Default restart policy

## Example Configuration

### For orac (4 shares):

```yaml
# host_vars/orac/vars.yml
samba_shares:
  - local_path: /opt/shares/outbox
    share_name: outbox
    writable: yes
  - local_path: /opt/homelab/www
    share_name: www
    writable: yes
  - local_path: /opt
    share_name: opt
    browseable: no
    writable: yes
  - local_path: ~/Dropbox
    share_name: dropbox
    writable: yes
```

### For jarvis/seraph (1 share):

```yaml
# host_vars/jarvis/vars.yml or host_vars/seraph/vars.yml
samba_shares:
  - local_path: /opt
    share_name: opt
    browseable: no
    writable: yes
```

## Example Playbook

```yaml
---
- hosts: homelab
  become: true
  roles:
    - role: samba
      when: "'samba' in services"
```

## Directory Structure

```
/opt/homelab/samba/
├── docker-compose.yml
└── .env
```

## Service Details

- **Container name**: `samba`
- **Port**: `445` (SMB)
- **Authentication**: Username/password (configured in `.env`)
- **Traefik**: Disabled (not a web service)

## Notes

- All shares are configured with authentication required
- Shares are not publicly accessible
- The `.env` file contains credentials and has restricted permissions (0600)
- Home directory paths (starting with `~`) are expanded by Docker, not created by Ansible
- The `opt` share is marked as non-browseable for security

## Author

Created for homelab modular infrastructure migration project.
