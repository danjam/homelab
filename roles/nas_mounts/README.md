# NAS Mounts Role

Mounts NAS shares to local directories using CIFS (SMB) protocol with systemd mount units for robust, automatic mounting.

## Overview

This role provides automated NAS share mounting with:
- CIFS/SMB protocol support
- Systemd mount units (more reliable than fstab)
- Automount capability (mount on access)
- Secure credential storage
- Per-machine mount configuration
- Automatic verification and health checks

## Requirements

- Ubuntu-based system
- Network access to NAS at specified IP
- Valid SMB credentials in vault
- `cifs-utils` package (installed by role)

## Role Variables

### NAS Configuration

```yaml
# Enable/disable NAS mounting (per host)
nas_enabled: false

# NAS server IP address
nas_ip: "192.168.1.60"

# List of shares to mount
nas_mounts:
  - share: MUSIC
    mount_point: /mnt/music
  - share: BACKUPS
    mount_point: /mnt/backups
```

### Credentials (from vault)

```yaml
nas_username: "{{ vault_nas_username }}"
nas_password: "{{ vault_nas_password }}"
```

**Security Note:** Credentials are stored in `/root/.smbcredentials` with mode 0600 (root only).

### Mount Options

```yaml
# Path to credentials file
nas_credentials_file: /root/.smbcredentials

# Mount options (used in systemd units)
# uid/gid: Maps remote files to local user
# iocharset: Character encoding
# file_mode/dir_mode: Permissions for files and directories
# nofail: System boots even if mount fails
# x-systemd.automount: Mount on first access
```

## Per-Machine Configuration

### orac (3 shares)

```yaml
nas_enabled: true
nas_ip: 192.168.1.60
nas_mounts:
  - share: MUSIC
    mount_point: /mnt/music
  - share: ROMS
    mount_point: /mnt/roms
  - share: BACKUPS
    mount_point: /mnt/backups
```

### jarvis (1 share)

```yaml
nas_enabled: true
nas_ip: 192.168.1.60
nas_mounts:
  - share: BACKUPS
    mount_point: /mnt/backups
```

### seraph (1 share)

```yaml
nas_enabled: true
nas_ip: 192.168.1.60
nas_mounts:
  - share: BACKUPS
    mount_point: /mnt/backups
```

## Dependencies

- `common` role (creates base directories)

## Example Playbook

```yaml
---
- name: Mount NAS shares
  hosts: homelab
  become: true
  
  roles:
    - role: nas_mounts
      when: nas_enabled | default(false)
      tags: ['nas']
```

### Deploy to Specific Machine

```bash
# Mount NAS on orac only
ansible-playbook playbooks/site.yml --limit orac --tags nas

# Deploy only to machines with nas_enabled=true
ansible-playbook playbooks/site.yml --tags nas
```

## What Gets Created

### Mount Point Directories

For each mount in `nas_mounts`, a directory is created:
- `/mnt/music` (orac only)
- `/mnt/roms` (orac only)
- `/mnt/backups` (all machines)

Owned by homelab user with 0755 permissions.

### Systemd Units

For each mount, two systemd units are created:

**Mount Unit** (`/etc/systemd/system/mnt-music.mount`):
- Defines the actual mount configuration
- Includes mount options and credentials
- Automatically mounts at boot

**Automount Unit** (`/etc/systemd/system/mnt-music.automount`):
- Mounts share on first access
- Unmounts after 300 seconds of inactivity (configurable)
- Reduces overhead for unused shares

### Credentials File

`/root/.smbcredentials`:
- Contains SMB username and password
- Mode 0600 (root only)
- Not visible in process lists
- Templated from vault variables


## Tags

This role supports the following tags:

- `nas`: Apply all NAS mount tasks
- `nas-install`: Install cifs-utils only
- `nas-dirs`: Create mount directories only
- `nas-credentials`: Deploy credentials file only
- `nas-systemd`: Create systemd units only
- `nas-mount`: Enable and start mounts only
- `nas-verify`: Verification tasks only

### Tag Usage Examples

```bash
# Install CIFS utilities only
ansible-playbook playbooks/site.yml --tags nas-install

# Create mount directories
ansible-playbook playbooks/site.yml --tags nas-dirs

# Update credentials
ansible-playbook playbooks/site.yml --tags nas-credentials

# Recreate systemd units
ansible-playbook playbooks/site.yml --tags nas-systemd

# Verify mounts
ansible-playbook playbooks/site.yml --tags nas-verify
```

## Verification

After deployment, verify mounts:

```bash
# Check if mount points exist
ls -la /mnt/

# Check systemd mount status
systemctl status mnt-backups.mount
systemctl status mnt-backups.automount

# Verify mount is active
mountpoint /mnt/backups

# List all mounts
mount | grep cifs

# Check filesystem usage
df -h | grep mnt

# View systemd logs
journalctl -u mnt-backups.mount -n 50
```

## Troubleshooting

### Mount fails with "Permission denied"

**Problem:** Incorrect SMB credentials or permissions.

**Solution:**
```bash
# Verify credentials file
sudo cat /root/.smbcredentials

# Test mount manually
sudo mount -t cifs //192.168.1.60/BACKUPS /mnt/backups \
  -o credentials=/root/.smbcredentials,uid=1000,gid=1000

# Check NAS logs for authentication errors
```

### Mount fails with "Host is down"

**Problem:** NAS not reachable on network.

**Solution:**
```bash
# Verify NAS IP is reachable
ping 192.168.1.60

# Check if SMB port is open
nc -zv 192.168.1.60 445

# Verify share exists
smbclient -L //192.168.1.60 -U username
```

### Systemd unit fails to start

**Problem:** Syntax error in systemd unit or mount issues.

**Solution:**
```bash
# Check systemd unit syntax
systemd-analyze verify /etc/systemd/system/mnt-backups.mount

# View detailed status
systemctl status mnt-backups.mount -l

# Manually start mount
sudo systemctl start mnt-backups.mount

# Check journal for errors
journalctl -xeu mnt-backups.mount
```

### Mount works manually but not via systemd

**Problem:** Systemd unit configuration or timing issues.

**Solution:**
```bash
# Ensure network is up before mounting
systemctl status network-online.target

# Reload systemd daemon
sudo systemctl daemon-reload

# Re-enable mount
sudo systemctl disable mnt-backups.mount
sudo systemctl enable mnt-backups.mount
sudo systemctl start mnt-backups.mount
```

### Share mounted but shows wrong permissions

**Problem:** uid/gid mapping incorrect.

**Solution:**
```bash
# Check current mount options
mount | grep /mnt/backups

# Verify user IDs
id danjam

# Remount with correct uid/gid
sudo umount /mnt/backups
sudo mount -t cifs //192.168.1.60/BACKUPS /mnt/backups \
  -o credentials=/root/.smbcredentials,uid=1000,gid=1000
```


## Important Notes

### Systemd vs Fstab

This role uses systemd mount units instead of `/etc/fstab` entries because:
- **Better error handling**: Failed mounts don't prevent boot
- **Dependencies**: Can specify network dependencies explicitly
- **Automount**: Mount on demand, unmount when idle
- **Logging**: Better integration with journalctl
- **Management**: Standard systemctl commands work

### Automount Behavior

Automount units (`*.automount`) provide:
- **Lazy mounting**: Share not mounted until first access
- **Auto-unmount**: After 300 seconds of inactivity
- **Resource saving**: Unused shares don't consume resources
- **Transparent**: Applications don't know the difference

### Security Considerations

- **Credentials**: Stored in root-only file (mode 0600)
- **Network**: NAS should be on trusted network
- **Encryption**: CIFS doesn't encrypt by default (use VPN if needed)
- **Authentication**: Use strong SMB passwords
- **Access**: Mount options restrict access to homelab user

### Network Dependencies

Mounts are configured with:
- `After=network-online.target`: Wait for network
- `Wants=network-online.target`: Require network service
- `nofail`: System boots even if mount fails

This ensures reliable mounting while preventing boot hangs.


## Files Created

```
/mnt/music                           # Mount point (orac only)
/mnt/roms                            # Mount point (orac only)
/mnt/backups                         # Mount point (all machines)
/root/.smbcredentials                # SMB credentials (all machines)
/etc/systemd/system/mnt-*.mount      # Systemd mount units
/etc/systemd/system/mnt-*.automount  # Systemd automount units
```

## Idempotency

This role is fully idempotent:
- Mount directories created only if missing
- Credentials file updated only if changed
- Systemd units recreated only if template changed
- Mounts started only if not already active
- Safe to run multiple times

## Usage Examples

### Full deployment

```bash
# Deploy to all machines with NAS enabled
ansible-playbook playbooks/site.yml --tags nas

# Deploy to specific machine
ansible-playbook playbooks/site.yml --limit orac --tags nas
```

### Verify mounts

```bash
# Run verification only
ansible-playbook playbooks/site.yml --tags nas-verify
```

### Update credentials

```bash
# Update vault with new credentials
ansible-vault edit inventory/group_vars/all/vault.yml

# Redeploy credentials and remount
ansible-playbook playbooks/site.yml --tags nas-credentials,nas-mount
```


### Remount all shares

```bash
# If shares unmount unexpectedly
ansible-playbook playbooks/site.yml --tags nas-mount
```

## Handlers

### Reload systemd

Reloads systemd daemon to recognize new/changed unit files.

**Triggered by:**
- Creation or modification of systemd mount units
- Creation or modification of systemd automount units

### Remount all NAS shares

Attempts to remount all NAS shares defined in configuration.

**Triggered manually or by:**
- Credential file changes (optional)

## Related Roles

- `common`: Creates base directory structure (prerequisite)
- `docker`: Not required but often deployed together
- Service roles using NAS mounts:
  - `navidrome`: Uses /mnt/music on orac

## License

MIT

## Author

Homelab Infrastructure Project
