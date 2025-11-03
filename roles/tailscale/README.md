# Tailscale Role

Installs and configures Tailscale VPN on Ubuntu systems with minimal configuration, embracing Tailscale's "it just works" philosophy.

## Overview

This role provides secure VPN networking between homelab machines using Tailscale. It follows a minimal configuration approach, trusting Tailscale's smart defaults for DNS, routing, and connectivity.

**Key Features:**
- ✅ Automated authentication with reusable auth key
- ✅ Tailscale SSH support (eliminates need for SSH keys)
- ✅ MagicDNS for seamless hostname resolution
- ✅ Automatic NAT traversal and port mapping
- ✅ Auto-updates enabled by default
- ✅ Idempotent - safe to run multiple times

## Why Minimal Configuration?

Tailscale is designed to work out-of-the-box with sensible defaults. This role only configures:
1. **Auth key** - Required for automated deployment
2. **SSH flag** - Optional but recommended for SSH-key-free management

Everything else (MagicDNS, routes, hostname, updates) is handled automatically by Tailscale's defaults.

## Variables

### Required Variables

```yaml
# From vault (inventory/group_vars/all/vault.yml)
vault_tailscale_auth_key: "tskey-auth-xxxxx"
```

### Optional Variables

```yaml
# defaults/main.yml
tailscale_enable_ssh: true  # Enable Tailscale SSH (default: true)
```

## Tailscale's Smart Defaults

The following features work automatically without configuration:

| Feature | Default Behavior |
|---------|------------------|
| **MagicDNS** | Enabled - resolves `machine.tailnet-name.ts.net` hostnames |
| **Hostname** | Uses system hostname (from inventory) |
| **Route Acceptance** | Enabled - receives advertised routes from other nodes |
| **NAT Traversal** | Automatic - direct connections when possible, relay when needed |
| **Auto-updates** | Enabled - Tailscale keeps itself updated |
| **Port Mapping** | Automatic - NAT-PMP and UPnP handle port forwarding |

## Benefits of Tailscale SSH

When `tailscale_enable_ssh: true`, you get:

- ✅ **No SSH keys needed** - Tailscale handles authentication
- ✅ **ACL-based access control** - Manage permissions from Tailscale admin console
- ✅ **Automatic credential rotation** - No manual key management
- ✅ **Audit logging** - See who accessed what and when
- ✅ **Works everywhere** - Same SSH access whether on LAN or remote

**Example:** After deployment, connect with:
```bash
ssh danjam@orac.tailnet-name.ts.net
```

No SSH key configuration needed!

## Usage

### Basic Usage

```yaml
- hosts: homelab
  roles:
    - role: tailscale
```

### With Custom Variables

```yaml
- hosts: homelab
  roles:
    - role: tailscale
      vars:
        tailscale_enable_ssh: false  # Use traditional SSH instead
```

### Selective Deployment with Tags

```bash
# Install only (don't authenticate)
ansible-playbook playbook.yml --tags tailscale-install

# Authenticate only (if already installed)
ansible-playbook playbook.yml --tags tailscale-auth

# Verify connection only
ansible-playbook playbook.yml --tags tailscale-verify

# Full deployment
ansible-playbook playbook.yml --tags tailscale
```

## Getting Your Auth Key

1. Visit Tailscale admin console: https://login.tailscale.com/admin/settings/keys
2. Generate a new **reusable** auth key
3. Optional: Set key to not expire (for long-term automation)
4. Optional: Tag the key (e.g., `tag:homelab`) for ACL management
5. Add to vault:
   ```bash
   ansible-vault edit inventory/group_vars/all/vault.yml
   ```

## Tags

| Tag | Description |
|-----|-------------|
| `tailscale` | All Tailscale tasks |
| `tailscale-install` | Installation tasks only |
| `tailscale-auth` | Authentication tasks only |
| `tailscale-verify` | Verification tasks only |

## How It Works

### Installation Phase
1. Adds Tailscale's official GPG key and apt repository
2. Installs the `tailscale` package
3. Starts and enables the `tailscaled` systemd service

### Authentication Phase
1. Checks if already authenticated (idempotent)
2. Runs `tailscale up --authkey=xxx --ssh` if not authenticated
3. Uses system hostname automatically

### Verification Phase
1. Queries Tailscale status via JSON API
2. Displays connection information:
   - Backend state (should be "Running")
   - Hostname and Tailscale IP
   - DNS name (e.g., `orac.tailnet-name.ts.net`)
   - MagicDNS and SSH status
3. Asserts connection is healthy

## MagicDNS

After deployment, machines can reach each other by:

| Method | Example | When to Use |
|--------|---------|-------------|
| Short name | `ping orac` | Within Tailscale network with MagicDNS |
| FQDN | `ping orac.tailnet-name.ts.net` | Always works |
| Tailscale IP | `ping 100.x.x.x` | Debugging or ACL testing |
| Local IP | `ping 192.168.1.51` | When on same LAN (fastest) |

## Troubleshooting

### Check Tailscale Status

```bash
# Basic status
tailscale status

# Detailed JSON status
tailscale status --json | jq

# Check if authenticated
tailscale status | grep "logged in"

# View IP addresses
tailscale ip -4  # IPv4
tailscale ip -6  # IPv6
```

### Common Issues

**Issue:** Role fails with "tailscaled socket not ready"
- **Cause:** Service didn't start in time
- **Fix:** Check `systemctl status tailscaled` for errors

**Issue:** Authentication fails
- **Cause:** Invalid or expired auth key
- **Fix:** Generate new auth key from Tailscale admin console

**Issue:** Can't connect to other machines
- **Cause:** Machines not on same Tailnet
- **Fix:** Verify all machines use same auth key/account

**Issue:** MagicDNS not working
- **Cause:** DNS configuration conflict
- **Fix:** Check `resolvectl status` - should show `100.100.100.100`

### DNS Verification

```bash
# Check MagicDNS is working
dig +short orac.tailnet-name.ts.net

# Check DNS resolver configuration
resolvectl status

# Test hostname resolution
ping seraph  # Should resolve via MagicDNS
```

### SSH Verification

```bash
# Test Tailscale SSH (if enabled)
ssh danjam@orac.tailnet-name.ts.net

# Check SSH configuration
tailscale status | grep -i ssh

# View SSH activity logs
journalctl -u tailscaled | grep -i ssh
```

## Dependencies

- Ubuntu 20.04 or later (Jammy repository used)
- Ansible 2.9 or later
- Internet connectivity for package installation
- Valid Tailscale account and auth key

## Example Playbook

```yaml
---
- name: Deploy Homelab with Tailscale
  hosts: homelab
  become: true

  roles:
    - role: tailscale
      tags: ['tailscale', 'networking']

    - role: common
      tags: ['common']

    - role: docker
      tags: ['docker']
```

## Security Considerations

- **Auth key storage:** Stored in encrypted Ansible vault
- **No-log flag:** Auth key never appears in Ansible logs
- **Reusable keys:** Consider expiration policy for auth keys
- **Tailscale ACLs:** Configure in Tailscale admin for fine-grained access
- **SSH access:** Tailscale SSH uses device authorization for security

## References

- [Tailscale Documentation](https://tailscale.com/kb/)
- [Tailscale SSH](https://tailscale.com/kb/1193/tailscale-ssh/)
- [MagicDNS](https://tailscale.com/kb/1081/magicdns/)
- [Auth Keys](https://tailscale.com/kb/1085/auth-keys/)

## Role Structure

```
roles/tailscale/
├── README.md            # This file
├── defaults/
│   └── main.yml        # Default variables (minimal)
├── handlers/
│   └── main.yml        # Service restart handler
└── tasks/
    └── main.yml        # Installation, auth, and verification tasks
```

## Version Information

- **Role Version:** 1.0.0
- **Tailscale Version:** Latest stable from official repository
- **Supported OS:** Ubuntu 22.04 (Jammy)
- **Ansible Version:** 2.9+

## License

MIT

## Author

Created for modular Ansible-managed homelab infrastructure.
