# CT Infrastructure Monorepo

Containerized infrastructure for data engineering and AI/LLM services, managed via Docker Compose and Portainer.

## Repository Structure

```
ct/
├── infrastructure/          # Core infrastructure (manual deployment)
│   ├── traefik/            # Reverse proxy and network creation
│   └── portainer/          # Container management UI
└── stacks/                 # Application stacks (Portainer Git deployment)
    ├── datalab/            # Data engineering stack
    ├── n8n/                # Workflow automation stack
    └── openwebui/          # LLM interface stack
```

### Infrastructure Layer

Core services deployed manually via SSH. These are stable and rarely change.

- **Traefik**: Reverse proxy with domain-based routing, creates the shared `ct-network`
- **Portainer**: Web UI for container management with Git sync capability

### Application Stacks

Application services deployed via Portainer Git integration for easy updates.

- **DataLab**: Complete data engineering environment with medallion architecture (bronze/silver/gold)
  - Mage AI for pipeline orchestration
  - Apache Superset for business intelligence
  - PostgreSQL data warehouse
  - Redis for caching

- **OpenWebUI**: LLM interface supporting both cloud and local models
  - Open WebUI for chat interface
  - LiteLLM proxy for external APIs (OpenAI, Anthropic, xAI)
  - Ollama for local model execution
  - PostgreSQL for logging

- **n8n**: Workflow automation platform for integrating services
  - n8n workflow engine with visual editor
  - PostgreSQL for workflow and credential storage
  - 500+ integrations and webhook support

## Network Architecture

All services share the `ct-network` bridge network:
- Created by Traefik on first startup
- All other services join as external network
- Enables domain-based routing via Traefik
- No port conflicts between stacks

## Deployment

### Current Status

**Infrastructure deployed and operational**
- Repository: https://github.com/scottcoggin/ct-infrastructure
- GitOps auto-update: Enabled (5-minute polling)
- All services healthy and accessible

### Prerequisites

- Docker host: `docker.homenet24.lan` (10.0.0.4)
- SSH access configured
- Local DNS records in Pi-hole
- Git repository: https://github.com/scottcoggin/ct-infrastructure

### Initial Setup

#### 1. Deploy Infrastructure Layer

```bash
# Deploy Traefik (creates ct-network)
ssh root@docker.homenet24.lan "mkdir -p /root/docker/apps/traefik"
scp infrastructure/traefik/* root@docker.homenet24.lan:/root/docker/apps/traefik/
ssh root@docker.homenet24.lan "cd /root/docker/apps/traefik && docker compose up -d"

# Deploy Portainer
ssh root@docker.homenet24.lan "mkdir -p /root/docker/apps/portainer"
scp infrastructure/portainer/* root@docker.homenet24.lan:/root/docker/apps/portainer/
ssh root@docker.homenet24.lan "cd /root/docker/apps/portainer && docker compose up -d"
```

#### 2. Configure DNS

Add A records in Pi-hole pointing to 10.0.0.4:
- `portainer.homenet24.lan`
- `mage.homenet24.lan`
- `superset.homenet24.lan`
- `n8n.homenet24.lan`
- `openwebui.homenet24.lan`

#### 3. Copy Support Files to Remote

Each stack requires support files on the remote host:

```bash
# DataLab support files
ssh root@docker.homenet24.lan "mkdir -p /root/docker/apps/datalab"
scp stacks/datalab/init-db.sql root@docker.homenet24.lan:/root/docker/apps/datalab/
scp stacks/datalab/superset-init.sh root@docker.homenet24.lan:/root/docker/apps/datalab/
ssh root@docker.homenet24.lan "mkdir -p /root/docker/apps/datalab/mage_data"

# OpenWebUI support files
ssh root@docker.homenet24.lan "mkdir -p /root/docker/apps/openwebui"
scp stacks/openwebui/init-db.sql root@docker.homenet24.lan:/root/docker/apps/openwebui/
scp stacks/openwebui/litellm_config.yaml root@docker.homenet24.lan:/root/docker/apps/openwebui/

# n8n support files
ssh root@docker.homenet24.lan "mkdir -p /root/docker/apps/n8n"
scp stacks/n8n/init-data.sh root@docker.homenet24.lan:/root/docker/apps/n8n/
```

#### 4. Deploy Stacks via Portainer

1. Access Portainer at http://portainer.homenet24.lan
2. For each stack (datalab, n8n, openwebui):
   - Navigate to Stacks → Add Stack → Git Repository
   - Repository URL: Your Git repository URL
   - Reference: `main`
   - Compose path: `stacks/[stack-name]/docker-compose.yml`
   - Environment variables: Copy from `.env.local` backup files
   - Deploy

### Git-Based Updates

Once configured, updates are automatic:
1. Make changes to docker-compose.yml or related files
2. Commit and push to Git repository
3. Portainer detects changes and redeploys (if auto-update enabled)
   - Or manually pull/redeploy via Portainer UI

## Environment Variables

Environment variables are NOT stored in Git. They are configured in:
- Infrastructure layer: `.env` files on remote host (deployed via SSH)
- Application stacks: Portainer UI environment variables section

`.env.example` files in Git show required variables without actual secrets.

## Service URLs

### Infrastructure
- Traefik Dashboard: http://docker.homenet24.lan:8080
- Portainer: http://portainer.homenet24.lan (or port 9000)

### DataLab Stack
- Mage AI: http://mage.homenet24.lan (or port 6789)
- Superset: http://superset.homenet24.lan (or port 8088)
- PostgreSQL: port 5432 (internal)
- Redis: port 6379 (internal)

### OpenWebUI Stack
- Open WebUI: http://openwebui.homenet24.lan (or port 3000)
- LiteLLM API: port 4000 (internal)
- Ollama API: port 11434 (internal)
- PostgreSQL: port 5432 (internal)

### n8n Stack
- n8n: http://n8n.homenet24.lan (or port 5678)
- PostgreSQL: port 5432 (internal)

## GitOps Workflow

### Making Changes

All application stack changes are automatically deployed via Portainer Git integration:

1. **Edit files locally**
   ```bash
   cd ~/ct
   # Edit stacks/datalab/docker-compose.yml or stacks/openwebui/docker-compose.yml
   ```

2. **Commit and push**
   ```bash
   git add .
   git commit -m "Description of changes"
   git push origin main
   ```

3. **Automatic deployment**
   - Portainer polls GitHub every 5 minutes
   - Detects changes automatically
   - Pulls updated compose files
   - Redeploys affected services

### Verifying GitOps Updates

**Via Portainer UI:**
- Navigate to **Stacks** → **datalab** or **openwebui**
- Scroll to "Git configuration" section
- Check "Last update" timestamp and commit hash

**Via Portainer logs:**
```bash
ssh root@docker.homenet24.lan "docker logs portainer 2>&1 | grep -i 'stack.*successful' | tail -5"
```

**Via container timestamps:**
```bash
ssh root@docker.homenet24.lan "docker ps --filter 'name=datalab' --format '{{.Names}}\t{{.CreatedAt}}'"
```

### Manual Force Update

If you can't wait for the polling interval:
1. Go to **Stacks** → [stack-name]
2. Click **Pull and redeploy**

## Common Operations

### View Logs
```bash
# Via SSH
ssh root@docker.homenet24.lan "cd /root/docker/apps/[stack] && docker compose logs -f [service]"

# Via Portainer
# Navigate to Stacks → [stack-name] → [service] → Logs
```

### Restart Service
```bash
# Via SSH
ssh root@docker.homenet24.lan "cd /root/docker/apps/[stack] && docker compose restart [service]"

# Via Portainer
# Navigate to Stacks → [stack-name] → [service] → Restart
```

### Update Support Files

**General workflow:**
```bash
# After updating init-db.sql, litellm_config.yaml, etc.
scp stacks/[stack]/[file] root@docker.homenet24.lan:/root/docker/apps/[stack]/

# Then restart affected services via Portainer or SSH
```

**LiteLLM configuration update (OpenWebUI):**
```bash
# 1. Copy updated config to remote host
scp stacks/openwebui/litellm_config.yaml root@docker.homenet24.lan:/root/docker/apps/openwebui/

# 2. Restart LiteLLM service
ssh root@docker.homenet24.lan "docker restart litellm"
```

**Database initialization files:**
```bash
# DataLab
scp stacks/datalab/init-db.sql root@docker.homenet24.lan:/root/docker/apps/datalab/

# OpenWebUI
scp stacks/openwebui/init-db.sql root@docker.homenet24.lan:/root/docker/apps/openwebui/

# Note: These only run on first startup; changing them requires volume recreation
```

## Documentation

Each stack has detailed documentation in its directory:
- `stacks/datalab/README.md`: DataLab architecture and usage
- `stacks/n8n/README.md`: n8n workflow automation and integrations
- `stacks/openwebui/README.md`: OpenWebUI configuration and models

## Backup Strategy

### Infrastructure Configuration
- Infrastructure docker-compose files are in Git
- Environment variables backed up as `.env.local` files (local only)

### Application Data
Persistent data is in Docker volumes. Backup via:
```bash
# PostgreSQL databases
ssh root@docker.homenet24.lan "cd /root/docker/apps/datalab && docker compose exec postgres pg_dump -U postgres datamart > /tmp/datamart_backup.sql"

# Mage pipelines (already on host)
rsync -av root@docker.homenet24.lan:/root/docker/apps/datalab/mage_data/ ./backups/mage_data/

# Ollama models (if needed)
ssh root@docker.homenet24.lan "docker run --rm -v openwebui_ollama-data:/data -v /tmp:/backup alpine tar czf /backup/ollama-data.tar.gz -C /data ."
```

## Troubleshooting

### Stack Won't Deploy
- Check Portainer logs for Git clone errors
- Verify support files exist on remote host at expected paths
- Ensure ct-network exists: `docker network ls`

### Service Can't Start
- Check environment variables in Portainer stack configuration
- View service logs via Portainer or SSH
- Verify health checks: `docker ps` shows health status

### Domain Not Resolving
- Verify DNS record in Pi-hole
- Check Traefik dashboard for registered routes
- Test with curl: `curl -H "Host: [domain]" http://10.0.0.4`

### Permission Issues
- Support files must be readable by container user
- Mage data directory needs write permissions: `chmod -R 777 /root/docker/apps/datalab/mage_data/`

## Security

### Secrets Management

✅ **No secrets committed to Git** - Verified clean repository
- `.env` and `.env.local` files are gitignored
- Only `.env.example` templates are committed (with placeholder values)
- Actual secrets stored in:
  - Infrastructure: `.env` files on remote host (deployed via SSH)
  - Application stacks: Portainer environment variables (configured via UI)

### Secret Storage Locations

**Local backups:**
- `~/ct/stacks/datalab/.env.local` - DataLab secrets (not in Git)
- `~/ct/stacks/openwebui/.env` - OpenWebUI secrets (not in Git)
- `~/ct/infrastructure/portainer/.env.local` - Portainer domain (not in Git)

**Production secrets:**
- Infrastructure layer: `/root/docker/apps/[service]/.env` on remote host
- Application stacks: Configured in Portainer UI (stored in Portainer's encrypted database)

### Verifying No Secrets in Git

```bash
# Check for API keys
git grep -i "sk-proj-\|sk-ant-\|xai-" || echo "No API keys found"

# Check for tracked .env files
git ls-files | grep "\.env$" || echo "No .env files tracked"

# Check .env.example files only have placeholders
grep -r "your_.*_key_here\|CHANGE_ME" stacks/*/.env.example
```

## Support

For issues specific to:
- DataLab stack: See `stacks/datalab/README.md`
- n8n stack: See `stacks/n8n/README.md`
- OpenWebUI stack: See `stacks/openwebui/README.md`
- Portainer Git integration: [Portainer Documentation](https://docs.portainer.io/)
- Traefik routing: [Traefik Documentation](https://doc.traefik.io/traefik/)
