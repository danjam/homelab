# Beszel Agent Role

Deploys the Beszel monitoring agent on a host machine. The agent collects system metrics and reports them to a Beszel hub.

## Features

- **System Monitoring**: Collects CPU, memory, disk, and network metrics
- **Docker Integration**: Read-only Docker socket access for container metrics
- **Host Network Mode**: Direct network access for accurate system monitoring
- **Secure Communication**: Uses SSH key-based authentication with hub
- **Lightweight**: Minimal resource footprint
- **Configurable**: Optional DNS servers and custom environment variables

## Requirements

- Docker and Docker Compose installed on target host
- Beszel hub running and accessible
- Unique agent key generated for this host
- Access to `/var/run/docker.sock` for container metrics

## Dependencies

None - this is a standalone monitoring agent.

## Role Variables

### Required Variables (in vault)

```yaml
# inventory/host_vars/{hostname}/vault.yml
vault_beszel_agent_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."
```

Each host must have its own unique agent key.

### Optional Variables (defaults/main.yml)

```yaml
# Docker image configuration
beszel_agent_image: henrygd/beszel-agent
beszel_agent_image_tag: latest

# Agent communication port
beszel_agent_port: 45876

# Docker socket path (read-only access)
beszel_agent_docker_socket: /var/run/docker.sock

# Base directory for homelab services
beszel_agent_base_dir: /opt/homelab

# Optional DNS servers (empty by default)
# Example: ["192.168.1.1", "192.168.1.2"]
beszel_agent_dns_servers: []

# Additional environment variables
beszel_agent_extra_env: {}
```

## Usage

### Basic Deployment

Add the role to your playbook:

```yaml
- hosts: all
  roles:
    - beszel_agent
```

### With DNS Configuration

If your network requires specific DNS servers:

```yaml
- hosts: seraph
  roles:
    - role: beszel_agent
      vars:
        beszel_agent_dns_servers:
          - 192.168.1.1
```

### With Custom Environment Variables

```yaml
- hosts: all
  roles:
    - role: beszel_agent
      vars:
        beszel_agent_extra_env:
          LOG_LEVEL: debug
          CUSTOM_VAR: value
```

## Agent Key Management

Each host needs a unique SSH key for secure communication with the hub.

### Generating Agent Keys

On the Beszel hub, generate a key for each agent:

```bash
# Generate key for host 'orac'
ssh-keygen -t ed25519 -f orac_agent_key -N ""
```

### Storing Keys in Ansible Vault

Store each host's key in its vault file:

```yaml
# inventory/host_vars/orac/vault.yml
vault_beszel_agent_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA..."

# inventory/host_vars/jarvis/vault.yml
vault_beszel_agent_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5BBBB..."

# inventory/host_vars/seraph/vault.yml
vault_beszel_agent_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5CCCC..."
```

### Registering Agents with Hub

After deploying the agent, register it with the hub using the agent's public key.

## Directory Structure

The role creates the following structure:

```
/opt/homelab/
├── beszel_agent/
│   └── docker-compose.yml    # Agent service definition
└── secrets/
    └── beszel_agent_key      # SSH key for hub communication
```

## Network Configuration

The agent uses **host network mode** for:
- Accurate network interface metrics
- Direct host system monitoring
- Simplified firewall configuration

The agent listens on port **45876** (configurable) for hub connections.

## Security Considerations

- **Read-Only Docker Socket**: Agent has read-only access to Docker socket
- **SSH Key Authentication**: Secure key-based authentication with hub
- **No Privileged Mode**: Runs without elevated privileges
- **Host Network**: Uses host network for system-level monitoring

## Collected Metrics

The agent monitors and reports:
- CPU usage and load averages
- Memory usage (used, free, cached)
- Disk usage and I/O statistics
- Network interface statistics
- Docker container metrics (via socket)
- System uptime and processes

## Troubleshooting

### Agent Not Connecting to Hub

Check agent logs:
```bash
cd /opt/homelab/beszel_agent
docker compose logs -f
```

Verify key is correct:
```bash
cat /opt/homelab/secrets/beszel_agent_key
```

### Permission Denied on Docker Socket

Ensure agent user has access:
```bash
ls -la /var/run/docker.sock
```

### Container Not Starting

Check service status:
```bash
cd /opt/homelab/beszel_agent
docker compose ps
docker compose logs beszel-agent
```

Verify configuration:
```bash
docker compose config
```

### Metrics Not Updating

Restart the agent:
```bash
cd /opt/homelab/beszel_agent
docker compose restart
```

Check hub connectivity:
```bash
docker compose exec beszel-agent ping <hub-ip>
```

## Example Playbook

Complete example deploying to all hosts:

```yaml
---
- name: Deploy Beszel monitoring agents
  hosts: all
  become: yes
  
  roles:
    - beszel_agent

  post_tasks:
    - name: Verify agent is running
      community.docker.docker_container_info:
        name: beszel-agent
      register: agent_info
    
    - name: Show agent status
      debug:
        msg: "Agent on {{ inventory_hostname }}: {{ agent_info.container.State.Status }}"
```

## Integration with Beszel Hub

This agent is designed to work with the `beszel` role (hub). Deploy them together:

```yaml
- name: Deploy Beszel monitoring system
  hosts: all
  become: yes
  
  tasks:
    - name: Deploy hub on seraph
      include_role:
        name: beszel
      when: inventory_hostname == 'seraph'
    
    - name: Deploy agents on all hosts
      include_role:
        name: beszel_agent
```

## Handlers

The role includes one handler:

- **Restart beszel_agent**: Restarts the agent when configuration changes

## Tags

No specific tags are implemented. Use standard Ansible tags:

```bash
ansible-playbook site.yml --tags beszel_agent
```

## License

MIT

## Author

Created for homelab Ansible migration project
