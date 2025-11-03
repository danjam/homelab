# Adding New Services Guide

## Overview

This guide shows how to add new services to your homelab using the existing Ansible structure.

## Architecture Patterns

All services follow these patterns:

- **Modular roles**: One role per service
- **Docker Socket Proxy**: No direct socket mounts (`/var/run/docker.sock`)
- **External networks**: `homelab` for web access, `{hostname}_docker_socket` for Docker API
- **Traefik labels**: Automatic HTTPS with Let's Encrypt
- **Templates**: Jinja2 templates for docker-compose files

## Step 1: Create a New Role

Create the role directory structure:

```bash
mkdir -p roles/myservice/{tasks,templates,handlers}
```

## Step 2: Create Role Tasks

Create `roles/myservice/tasks/main.yml`:

```yaml
---
# MyService role - Deploy my service

- name: Create service directory
  ansible.builtin.file:
    path: "{{ homelab_dir }}/myservice"
    state: directory
    owner: "{{ docker_user }}"
    group: "{{ docker_user }}"
    mode: '0755'

- name: Deploy docker-compose
  ansible.builtin.template:
    src: docker-compose.yml.j2
    dest: "{{ homelab_dir }}/myservice/docker-compose.yml"
    owner: "{{ docker_user }}"
    group: "{{ docker_user }}"
    mode: '0644'
  notify: restart myservice

- name: Deploy .env file
  ansible.builtin.template:
    src: .env.j2
    dest: "{{ homelab_dir }}/myservice/.env"
    owner: "{{ docker_user }}"
    group: "{{ docker_user }}"
    mode: '0600'
  notify: restart myservice

- name: Start service
  community.docker.docker_compose_v2:
    project_src: "{{ homelab_dir }}/myservice"
    state: present
    pull: "{{ auto_pull_images | default(true) }}"
    recreate: "{{ recreate_containers | default('auto') }}"
```

## Step 3: Create Docker Compose Template

Create `roles/myservice/templates/docker-compose.yml.j2`:

```yaml
---
services:
  myservice:
    image: myservice/myservice:latest
    container_name: myservice
    restart: {{ default_container_restart_policy }}
    networks:
      - {{ myservice_network }}
    environment:
      - PUID={{ puid }}
      - PGID={{ pgid }}
      - TZ={{ timezone }}
    volumes:
      - {{ myservice_config_path }}:/config
      - {{ myservice_data_path }}:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myservice.{{ domain }}`)"
      - "traefik.http.routers.myservice.entrypoints=websecure"
      - "traefik.http.routers.myservice.tls.certresolver=letsencrypt"
      - "traefik.http.services.myservice.loadbalancer.server.port=8080"
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

networks:
  {{ myservice_network }}:
    name: {{ myservice_network }}
    external: true
```

## Step 4: Create Defaults (Optional)

If your service needs default variables, create `roles/myservice/defaults/main.yml`:

```yaml
---
# MyService role defaults

myservice_image: "myservice/myservice:latest"
myservice_dir: "{{ homelab_dir }}/myservice"
myservice_network: homelab
container_restart_policy: "{{ default_container_restart_policy }}"
```

## Step 5: Create Handlers

Create `roles/myservice/handlers/main.yml`:

```yaml
---
# MyService handlers

- name: restart myservice
  community.docker.docker_compose_v2:
    project_src: "{{ homelab_dir }}/myservice"
    state: restarted
```

## Step 6: Add to Machine Variables

Add to machine's `host_vars/{orac,jarvis,seraph}/vars.yml`:

```yaml
# Add to services list
services:
  - docker-socket-proxy
  - traefik
  - myservice  # Add your service here
```

## Step 7: Add Secrets (if needed)

If your service needs secrets, add to `inventory/group_vars/all/vault.yml`:

```yaml
vault_myservice_api_key: "your-secret-key"
vault_myservice_password: "your-password"
```

Then edit the encrypted vault:
```bash
ansible-vault edit inventory/group_vars/all/vault.yml
```

## Step 8: Update Playbook

Add to `playbooks/site.yml` (when it's created):

```yaml
    - role: myservice
      when: "'myservice' in services"
      tags: ['myservice', 'apps']
```

## Step 9: Deploy

```bash
# Dry run first
ansible-playbook playbooks/site.yml --tags myservice --check --diff

# Deploy
ansible-playbook playbooks/site.yml --tags myservice

# Or deploy to specific machine
ansible-playbook playbooks/site.yml --tags myservice --limit orac
```

## Common Service Patterns

### Service Needing Docker Access

Use Docker Socket Proxy (don't mount socket directly):

```yaml
services:
  myservice:
    environment:
      - DOCKER_HOST=tcp://docker-socket-proxy:2375
    networks:
      - homelab
      - {{ hostname }}_docker_socket

networks:
  homelab:
    name: homelab
    external: true
  {{ hostname }}_docker_socket:
    name: {{ hostname }}_docker_socket
    external: true
```

### Service with Database

```yaml
services:
  app:
    networks:
      - homelab
      - internal

  database:
    image: postgres:15
    networks:
      - internal

networks:
  homelab:
    name: homelab
    external: true
  internal:
    name: myservice_internal
    driver: bridge
```

### Service with NAS Volume (orac only)

```yaml
volumes:
  - /mnt/music:/music:ro  # Read-only NAS mount
  - {{ myservice_data }}:/data:rw
```

## Tips

1. **Start with existing roles** - Copy `dozzle` or `whatsupdocker` as simple templates
2. **Use Docker Socket Proxy** - Never mount `/var/run/docker.sock` directly
3. **Test on one machine first** - Use `--limit jarvis` (simplest setup)
4. **Use check mode** - Test before deploying with `--check --diff`
5. **Keep roles simple** - One service per role
6. **Add healthchecks** - Docker healthchecks help monitoring
7. **Tag appropriately** - Makes selective deployment easier
8. **Document in README** - Create `roles/myservice/README.md`

## Reference Examples

See existing roles for patterns:
- **Simple web service**: `roles/dozzle/`
- **Docker API access**: `roles/whatsupdocker/`
- **Complex with secrets**: `roles/traefik/`
- **Monitoring**: `roles/beszel/`
