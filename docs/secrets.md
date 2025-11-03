# Secret Management Guide

## Overview

This homelab uses `ansible-vault` to encrypt sensitive data. **All secrets are stored in a single encrypted vault file** at `inventory/group_vars/all/vault.yml`.

## Vault Structure

**Single Vault File:**
- `inventory/group_vars/all/vault.yml` - ALL secrets for ALL machines

This consolidated approach simplifies secret management and avoids unnecessary complexity of per-host vault files.

## Setup

### First Time

```bash
# 1. Run setup playbook to generate Beszel ED25519 keypair
ansible-playbook playbooks/setup-secrets.yml

# 2. Edit vault and fill in your secrets
ansible-vault edit inventory/group_vars/all/vault.yml

# Note: The vault file is encrypted automatically when using 'ansible-vault edit'
```

## Required Secrets

All secrets in `inventory/group_vars/all/vault.yml`:

### Auto-Generated (by playbooks/setup-secrets.yml)
- `vault_beszel_hub_private_key` - Beszel hub private key (ED25519)
- `vault_beszel_hub_public_key` - Beszel hub public key (shared by all agents)

### You Must Provide

**Core Infrastructure:**
- `vault_cloudflare_email` - Cloudflare account email
- `vault_cloudflare_dns_token` - Cloudflare DNS API token (for Let's Encrypt)
- `vault_default_password` - Default password for services
- `vault_tailscale_auth_key` - Tailscale reusable auth key (for VPN networking)

**Notifications:**
- `vault_telegram_bot_token` - Telegram bot token (for jarvis/seraph notifications)
- `vault_telegram_chat_id` - Telegram chat ID

**orac-specific (Navidrome):**
- `vault_lastfm_apikey` - Last.fm API key
- `vault_lastfm_secret` - Last.fm API secret
- `vault_spotify_id` - Spotify client ID
- `vault_spotify_secret` - Spotify client secret

**orac-specific (NAS Mounts):**
- `vault_nas_username` - NAS username for CIFS/SMB mounts
- `vault_nas_password` - NAS password

## Working with the Vault File

### Edit Encrypted Vault

```bash
ansible-vault edit inventory/group_vars/all/vault.yml
```

### View Without Editing

```bash
ansible-vault view inventory/group_vars/all/vault.yml
```

### Change Vault Password

```bash
ansible-vault rekey inventory/group_vars/all/vault.yml
```

### Manual Encryption (rarely needed)

```bash
# Encrypt unencrypted vault
ansible-vault encrypt inventory/group_vars/all/vault.yml

# Decrypt temporarily (NOT recommended - use edit/view instead)
ansible-vault decrypt inventory/group_vars/all/vault.yml
```

## Getting API Credentials

### Tailscale Auth Key
1. Log in to Tailscale admin console: https://login.tailscale.com/admin/settings/keys
2. Generate Keys → Auth keys
3. Create a **reusable** auth key
4. Optional: Set key to not expire (for long-term automation)
5. Optional: Tag the key (e.g., `tag:homelab`) for ACL management
6. Copy the key (starts with `tskey-auth-`)

**Important:** Use a reusable key so all machines can use the same key.

### Cloudflare DNS Token
1. Log in to Cloudflare dashboard
2. Go to Profile → API Tokens
3. Create Token → Edit zone DNS template
4. Select your domain
5. Copy the token

### Last.fm API
1. Go to https://www.last.fm/api/account/create
2. Create an API account
3. Copy API key and shared secret

### Spotify API
1. Go to https://developer.spotify.com/dashboard
2. Create an app
3. Copy Client ID and Client Secret

### Telegram Bot
1. Message @BotFather on Telegram
2. Create a new bot
3. Copy the bot token
4. Get chat ID by messaging your bot and checking updates

## Vault Password

The vault password is stored in `.ansible-vault-pass` (not in repo).

```bash
# Create password file
openssl rand -base64 32 > .ansible-vault-pass
chmod 600 .ansible-vault-pass
```

**Important:** Backup this password securely!

## Best Practices

1. **Never commit unencrypted vault** - Always use `ansible-vault edit`
2. **Verify encryption** before committing:
   ```bash
   head -1 inventory/group_vars/all/vault.yml
   # Should show: $ANSIBLE_VAULT;1.1;AES256
   ```
3. **Use edit, not decrypt** - Never decrypt manually
4. **Backup vault password** - Store `.ansible-vault-pass` securely
5. **Rotate tokens periodically** - Update external API tokens regularly
6. **Single source of truth** - All secrets in one vault file
