# Portainer Stack

Portainer CE (Community Edition) for managing Docker containers, images, volumes, and networks through a web interface.

## Features

- **Web UI**: Manage all Docker resources from a browser
- **Stack Management**: Deploy and manage Docker Compose stacks
- **Multi-container Visibility**: View logs, stats, and health across all services
- **Environment Variables**: Manage `.env` files through the UI
- **Git Integration**: Auto-deploy stacks from Git repositories

## Prerequisites

- `ct-network` must exist (created by datalab stack's Traefik service)
- Traefik must be running for domain-based routing

## Quick Start

### 1. Setup Environment

```bash
# Copy environment template
cp .env.example .env

# Edit if needed (default domain: portainer.homenet24.lan)
nano .env
```

### 2. Deploy Portainer

**Local deployment:**
```bash
docker compose up -d
```

**Remote deployment to docker.homenet24.lan:**
```bash
# Copy files to remote
scp docker-compose.yml .env root@docker.homenet24.lan:/root/docker/apps/portainer/

# Deploy on remote
ssh root@docker.homenet24.lan "cd /root/docker/apps/portainer && docker compose up -d"
```

### 3. Initial Setup

1. Access Portainer at http://portainer.homenet24.lan (or http://docker.homenet24.lan:9000)
2. Create admin user (first time only - 5 minute timeout)
3. Select "Get Started" to manage the local Docker environment
4. Portainer is now ready to manage your stacks!

## Access Points

- **Via Traefik**: http://portainer.homenet24.lan
- **Direct HTTP**: http://docker.homenet24.lan:9000
- **Direct HTTPS**: https://docker.homenet24.lan:9443

## Usage

### Managing Stacks

**Deploy a stack:**
1. Go to **Stacks** → **Add stack**
2. Name your stack (e.g., `datalab`, `openwebui`)
3. Choose method:
   - **Web editor**: Paste docker-compose.yml content
   - **Upload**: Upload compose file
   - **Git repository**: Connect to repo for auto-updates
4. Add environment variables
5. Click **Deploy stack**

**Update a stack:**
1. Go to **Stacks** → Select stack → **Editor**
2. Make changes
3. Click **Update the stack**
4. Or use **Pull and redeploy** if using Git

**View logs:**
- **Stacks** → Select stack → Click service name → **Logs**
- Real-time log streaming available

**Restart services:**
- **Stacks** → Select stack → Click service name → **Restart**

### Managing Containers

- **Containers**: View all running/stopped containers
- **Images**: Pull, remove, inspect images
- **Volumes**: Create, remove, inspect volumes
- **Networks**: Manage Docker networks

## Network Integration

Portainer joins the `ct-network` to integrate with:
- Traefik (reverse proxy for domain routing)
- DataLab services (PostgreSQL, Mage, Superset, Redis)
- OpenWebUI services (LiteLLM, Ollama, Open WebUI)

## DNS Configuration

Add A record in Pi-hole or local DNS:
- Domain: `portainer.homenet24.lan`
- IP: `10.0.0.4` (or your Docker host IP)

## Common Commands

### Service Management

```bash
# View logs
docker compose logs -f portainer

# Restart Portainer
docker compose restart portainer

# Stop Portainer
docker compose down

# Update Portainer image
docker compose pull
docker compose up -d
```

### Access Portainer Data

```bash
# Backup Portainer data
docker run --rm -v portainer_data:/data -v $(pwd):/backup alpine tar czf /backup/portainer-backup.tar.gz -C /data .

# Restore Portainer data
docker run --rm -v portainer_data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/portainer-backup.tar.gz"
```

## Troubleshooting

### Portainer won't start

```bash
# Check if ct-network exists
docker network inspect ct-network

# If not, start datalab stack first (creates network)
cd ~/ct/datalab && docker compose up -d

# Then start Portainer
cd ~/ct/portainer && docker compose up -d
```

### Can't access Portainer UI

1. **Check if running:**
   ```bash
   docker ps | grep portainer
   ```

2. **Check Traefik routing:**
   - Visit http://docker.homenet24.lan:8080 (Traefik dashboard)
   - Look for portainer router

3. **Try direct access:**
   - http://docker.homenet24.lan:9000

4. **Check DNS:**
   ```bash
   nslookup portainer.homenet24.lan
   ```

### Admin user timeout

If you don't create an admin user within 5 minutes of first startup:

```bash
# Restart Portainer
docker compose restart portainer

# You'll have another 5 minutes to create admin
```

## Security Considerations

- Use strong admin password
- Enable 2FA in Portainer settings (recommended)
- Docker socket is mounted read-only (`:ro`)
- Use HTTPS (port 9443) in production
- Limit access to Portainer in firewall rules
- **WARNING:** Portainer has full Docker control - secure access appropriately

## Volume Data

Portainer stores all its data in the `portainer_data` volume:
- User accounts and roles
- Stack definitions
- Environment configurations
- Settings and preferences

**Backup this volume regularly!**

## Next Steps

After deploying Portainer:
1. Create admin account
2. Deploy datalab stack (if not already running)
3. Deploy openwebui stack through Portainer UI
4. Set up Git integration for auto-updates (optional)
5. Configure additional endpoints (if managing multiple Docker hosts)

## Resources

- [Portainer Documentation](https://docs.portainer.io/)
- [Portainer CE vs Business](https://www.portainer.io/products/community-vs-business)
- [Stack Management Guide](https://docs.portainer.io/user/docker/stacks)
