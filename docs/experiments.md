# Experimenting in Your Homelab

## Philosophy

**This is a LAB - experimentation is part of it.**

Your homelab should support both:
- **Production services** - Stable, managed, version-controlled with Ansible
- **Experiments** - Quick tests, new tools, learning projects

There's no artificial separation between them. Everything lives in `/opt/homelab/` and they coexist peacefully.

## How It Works

**The Simple Rule:**

| Where Declared? | Who Manages It? |
|----------------|-----------------|
| In `host_vars/{machine}/vars.yml` services list | Ansible |
| Not in services list | You (manually) |

That's it. Ansible only touches what it's told to manage. Everything else is yours to experiment with.

## Starting an Experiment

### Quick Start

```bash
# SSH to any machine
ssh orac

# Create experiment directory
cd /opt/homelab
mkdir my-cool-app && cd my-cool-app

# Create docker-compose.yml
vim docker-compose.yml
```

**Example experiment compose file:**
```yaml
services:
  my-cool-app:
    image: some-image:latest
    container_name: my-cool-app
    restart: unless-stopped
    ports:
      - "3456:80"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - ./data:/data
```

```bash
# Start it
docker compose up -d

# Check logs
docker compose logs -f

# Done experimenting?
docker compose down
```

### Using External Networks

Want your experiment to use the same networks as Ansible-managed services?

```yaml
services:
  my-cool-app:
    image: some-image:latest
    container_name: my-cool-app
    restart: unless-stopped
    networks:
      - homelab  # Use existing network
    environment:
      - PUID=1000
      - PGID=1000

networks:
  homelab:
    external: true  # Use the network created by docker role
```

**Available external networks:**
- `homelab` - For web-accessible services (with Traefik)
- `monitoring` - For monitoring services (Beszel)

## Using Traefik for HTTPS

Want your experiment accessible via HTTPS with automatic certificates?

```yaml
services:
  my-cool-app:
    image: some-image:latest
    container_name: my-cool-app
    restart: unless-stopped
    networks:
      - homelab
    labels:
      # Enable Traefik
      - "traefik.enable=true"

      # Define the host rule
      - "traefik.http.routers.my-cool-app.rule=Host(`my-cool-app.orac.dannyjames.net`)"

      # Use the HTTPS entrypoint
      - "traefik.http.routers.my-cool-app.entrypoints=websecure"

      # Specify the port (if not 80)
      - "traefik.http.services.my-cool-app.loadbalancer.server.port=8080"

networks:
  homelab:
    external: true
```

**Then:**
1. Add DNS record: `my-cool-app.orac.dannyjames.net` → your IP
2. Access: `https://my-cool-app.orac.dannyjames.net`
3. Traefik handles SSL automatically

## Promoting an Experiment

When an experiment becomes a keeper, promote it to Ansible management:

### Step 1: Add to Services List

Edit `host_vars/{machine}/vars.yml`:

```yaml
services:
  - traefik
  - navidrome
  - my-cool-app  # ← Add this
```

### Step 2: Create Ansible Role

```bash
# On your control machine
cd ~/Projects/homelab

# Create role structure
mkdir -p roles/my-cool-app/{tasks,templates,defaults,handlers}
```

**roles/my-cool-app/defaults/main.yml:**
```yaml
---
my_cool_app_dir: "{{ homelab_dir }}/my-cool-app"
```

**roles/my-cool-app/tasks/main.yml:**
```yaml
---
- name: Create my-cool-app directory
  ansible.builtin.file:
    path: "{{ my_cool_app_dir }}"
    state: directory
    owner: "{{ docker_user }}"
    group: "{{ docker_user }}"
    mode: '0755'

- name: Deploy docker-compose.yml
  ansible.builtin.template:
    src: docker-compose.yml.j2
    dest: "{{ my_cool_app_dir }}/docker-compose.yml"
    owner: "{{ docker_user }}"
    group: "{{ docker_user }}"
    mode: '0644'
  notify: restart my-cool-app

- name: Start my-cool-app
  community.docker.docker_compose_v2:
    project_src: "{{ my_cool_app_dir }}"
    state: present
```

**roles/my-cool-app/templates/docker-compose.yml.j2:**
```yaml
# Your docker-compose.yml content (templatized as needed)
services:
  my-cool-app:
    image: some-image:latest
    container_name: my-cool-app
    restart: {{ default_container_restart_policy }}
    networks:
      - homelab
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.my-cool-app.rule=Host(`my-cool-app.{{ domain }}`)"
      - "traefik.http.routers.my-cool-app.entrypoints=websecure"

networks:
  homelab:
    external: true
```

**roles/my-cool-app/handlers/main.yml:**
```yaml
---
- name: restart my-cool-app
  community.docker.docker_compose_v2:
    project_src: "{{ my_cool_app_dir }}"
    state: restarted
```

### Step 3: Deploy via Ansible

```bash
# Deploy just this service
ansible-playbook playbooks/site.yml --tags my-cool-app --limit orac

# Or deploy everything to orac
ansible-playbook playbooks/site.yml --limit orac
```

### Step 4: Clean Up Manual Version

```bash
# On the machine
ssh orac
cd /opt/homelab/my-cool-app

# Ansible already redeployed it, so just remove old files if needed
# (Ansible will maintain it from now on)
```

## Cleanup

Done with an experiment?

```bash
ssh orac
cd /opt/homelab/my-cool-app

# Stop and remove containers
docker compose down

# Optional: Remove volumes too
docker compose down -v

# Remove the directory
cd ..
rm -rf my-cool-app
```

That's it. No Ansible involvement needed.

## Examples

### Example 1: Testing a New Database

```bash
ssh orac
cd /opt/homelab
mkdir postgres-test && cd postgres-test

cat > docker-compose.yml << 'EOF'
services:
  postgres:
    image: postgres:16
    container_name: postgres-test
    environment:
      POSTGRES_PASSWORD: testpassword
      POSTGRES_USER: testuser
      POSTGRES_DB: testdb
    ports:
      - "5433:5432"
    volumes:
      - ./data:/var/lib/postgresql/data
EOF

docker compose up -d
docker compose logs -f

# Test it
psql -h orac -p 5433 -U testuser -d testdb

# Done testing
docker compose down -v
cd .. && rm -rf postgres-test
```

### Example 2: Web App with Traefik

```bash
ssh orac
cd /opt/homelab
mkdir whoami-test && cd whoami-test

cat > docker-compose.yml << 'EOF'
services:
  whoami:
    image: traefik/whoami
    container_name: whoami-test
    networks:
      - homelab
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.whoami-test.rule=Host(`whoami.orac.dannyjames.net`)"
      - "traefik.http.routers.whoami-test.entrypoints=websecure"
      - "traefik.http.services.whoami-test.loadbalancer.server.port=80"

networks:
  homelab:
    external: true
EOF

docker compose up -d

# Visit: https://whoami.orac.dannyjames.net
# (after adding DNS record)
```

### Example 3: Temporary Build Container

```bash
ssh orac
cd /opt/homelab
mkdir builder && cd builder

cat > docker-compose.yml << 'EOF'
services:
  builder:
    image: node:20
    container_name: temp-builder
    working_dir: /app
    volumes:
      - /opt/homelab/my-project:/app
    command: sh -c "npm install && npm run build"
EOF

docker compose up

# Build complete, clean up
docker compose down
cd .. && rm -rf builder
```

## FAQ

### Q: Will Ansible remove my experiments?

**A:** No. Ansible only manages services in the `services:` list. It never removes undeclared directories or containers.

### Q: Can experiments use the same networks as Ansible services?

**A:** Yes! Use `external: true` to reference networks created by the docker role (`homelab`, `monitoring`).

### Q: Can I use Traefik for experiments?

**A:** Absolutely. Just add Traefik labels and use the `homelab` network. Traefik doesn't care who created the container.

### Q: What happens if I run Ansible while experiments are running?

**A:** Nothing. Ansible only touches its declared services. Your experiments keep running.

### Q: Can I have an experiment and an Ansible service with the same name?

**A:** Bad idea. They'd conflict over the container name and directory. Use different names.

### Q: Should I commit experiments to git?

**A:** No. Experiments are ephemeral. Only promote to Ansible (and git) when they're keepers.

### Q: Can I mix manual and Ansible management of the same service?

**A:** No. Pick one:
- **Manual**: You handle everything (docker compose up/down)
- **Ansible**: Ansible handles everything (playbook runs)

Don't fight over the same service.

### Q: What if I accidentally add an experiment to the services list?

**A:** Ansible will deploy the role when you run the playbook. If the role doesn't exist yet, the playbook will fail. Just remove it from the services list.

### Q: Can experiments survive machine reboots?

**A:** Yes, if you use `restart: unless-stopped` or `restart: always` in your compose file. Experiments work exactly like Ansible-managed services in this regard.

### Q: How do I list all non-Ansible containers?

```bash
# All containers
docker ps

# Compare to services list in host_vars/{machine}/vars.yml
# Anything not in the list is manual/experiment
```

### Q: Should experiments use /opt/homelab?

**A:** Yes. Keeps everything in one place and allows reuse of networks. But if you prefer a different location for truly temporary stuff, that works too.

## Best Practices

1. **Name experiments clearly** - Use descriptive names so you remember what they're for
2. **Document why** - Add a README or comment in compose file about what you're testing
3. **Clean up regularly** - Don't let old experiments pile up
4. **Use volumes for data** - Makes it easy to remove the container but keep data
5. **Test in experiments first** - Before promoting to Ansible, make sure it works
6. **Use restart policies** - `unless-stopped` for things that should survive reboots
7. **Follow naming patterns** - Stay consistent with existing services when promoting

## Summary

**The homelab coexistence model:**
- ✅ Quick experiments? Just `docker compose up` - no ceremony
- ✅ Keeper service? Promote to Ansible - now it's managed
- ✅ Both coexist peacefully in `/opt/homelab/`
- ✅ Ansible never removes your experiments
- ✅ No artificial separation needed

**Your homelab, your rules.** Experiment freely, promote when ready.
