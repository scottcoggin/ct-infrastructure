# Traefik Reverse Proxy

Traefik v2.10 reverse proxy for domain-based routing across all CT stacks. This is core infrastructure that creates the `ct-network` shared by all services.

## Purpose

- **Reverse Proxy**: Route HTTP traffic based on domain names
- **Service Discovery**: Automatically detect Docker containers with Traefik labels
- **Network Creation**: Creates and manages the `ct-network` bridge network
- **Dashboard**: Web UI for monitoring routes and services

## Architecture Role

Traefik is the foundation of the CT infrastructure:

```
Traefik (creates ct-network)
   ├─ Portainer (portainer.homenet24.lan)
   ├─ DataLab Stack
   │  ├─ Mage (mage.homenet24.lan)
   │  └─ Superset (superset.homenet24.lan)
   └─ OpenWebUI Stack
      └─ Open WebUI (openwebui.homenet24.lan)
```

## Key Features

- **Docker Provider**: Automatically discovers containers with Traefik labels
- **HTTP Entrypoint**: Listens on port 80 for incoming traffic
- **Dashboard**: Accessible on port 8080 for monitoring
- **No Default Exposure**: Containers must have `traefik.enable=true` label

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+
- No other service using ports 80 or 8080

## Quick Start

### 1. Deploy Traefik

**Local deployment:**
```bash
docker compose up -d
```

**Remote deployment to docker.homenet24.lan:**
```bash
# Create directory on remote
ssh root@docker.homenet24.lan "mkdir -p /root/docker/apps/traefik"

# Copy files
scp docker-compose.yml root@docker.homenet24.lan:/root/docker/apps/traefik/

# Deploy
ssh root@docker.homenet24.lan "cd /root/docker/apps/traefik && docker compose up -d"
```

### 2. Verify Deployment

```bash
# Check Traefik is running
ssh root@docker.homenet24.lan "docker ps | grep traefik"

# Verify ct-network was created
ssh root@docker.homenet24.lan "docker network inspect ct-network"

# Access dashboard
# Visit: http://docker.homenet24.lan:8080
```

## Dashboard Access

- **URL**: http://docker.homenet24.lan:8080
- **Features**:
  - View all HTTP routers and their rules
  - Monitor service health
  - See middleware configurations
  - Real-time traffic metrics

## How Services Connect

Services join Traefik by:

1. **Joining ct-network** (external network)
2. **Adding Traefik labels** in docker-compose.yml:

```yaml
services:
  my-service:
    image: my-image
    networks:
      - ct-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myservice.homenet24.lan`)"
      - "traefik.http.routers.myservice.entrypoints=web"
      - "traefik.http.services.myservice.loadbalancer.server.port=8080"

networks:
  ct-network:
    external: true
    name: ct-network
```

## Network Details

**Network Name**: `ct-network`
**Driver**: bridge
**Scope**: local
**Created By**: Traefik docker-compose.yml

All services in the CT infrastructure must join this network to communicate and use Traefik routing.

## Configuration

Traefik is configured via command-line flags in docker-compose.yml:

- `--api.insecure=true`: Enable dashboard without authentication (local network only)
- `--providers.docker=true`: Enable Docker provider for service discovery
- `--providers.docker.exposedbydefault=false`: Require explicit `traefik.enable=true` label
- `--entrypoints.web.address=:80`: HTTP entrypoint on port 80

## Common Commands

### Service Management

```bash
# View logs
docker compose logs -f traefik

# Restart Traefik
docker compose restart traefik

# Stop Traefik (WARNING: stops all domain-based routing)
docker compose down

# Update Traefik image
docker compose pull
docker compose up -d
```

### Network Management

```bash
# Inspect ct-network
docker network inspect ct-network

# List all containers on ct-network
docker network inspect ct-network -f '{{range .Containers}}{{.Name}} {{end}}'
```

### Troubleshooting

```bash
# Check Traefik logs
docker logs traefik

# Test HTTP routing
curl -H "Host: portainer.homenet24.lan" http://docker.homenet24.lan

# View all active routes (from Traefik API)
curl http://docker.homenet24.lan:8080/api/http/routers | jq
```

## Troubleshooting

### Port 80 Already in Use

If another service is using port 80:

```bash
# Find what's using port 80
sudo netstat -tulpn | grep :80

# Option 1: Stop conflicting service
sudo systemctl stop nginx  # example

# Option 2: Change Traefik port in docker-compose.yml
ports:
  - "8080:80"  # Change from "80:80"
```

Then update DNS/access to use the new port.

### Service Not Routing Through Traefik

1. **Check service has Traefik labels:**
   ```bash
   docker inspect <container-name> | grep -A 10 Labels
   ```

2. **Check service is on ct-network:**
   ```bash
   docker network inspect ct-network | grep <container-name>
   ```

3. **Check Traefik dashboard:**
   - Visit http://docker.homenet24.lan:8080
   - Look for router in HTTP → Routers section

4. **Check DNS resolution:**
   ```bash
   nslookup myservice.homenet24.lan
   ```

### Dashboard Not Accessible

```bash
# Verify Traefik is running
docker ps | grep traefik

# Check port 8080 is mapped
docker port traefik

# Test direct access
curl http://docker.homenet24.lan:8080/api/http/routers
```

### ct-network Doesn't Exist

If ct-network doesn't exist after Traefik deployment:

```bash
# Check Traefik logs
docker compose logs traefik

# Recreate with network
docker compose down
docker compose up -d

# Verify network created
docker network ls | grep ct-network
```

## Security Considerations

- Dashboard is insecure (no auth) - only use on trusted local network
- For production: Enable dashboard authentication
- Docker socket is mounted read-only (`:ro`)
- Only containers with explicit labels are exposed
- Consider firewall rules to restrict access to ports 80 and 8080

## When to Restart Traefik

Traefik automatically detects new containers - **no restart needed** when:
- Deploying new services with Traefik labels
- Starting/stopping containers
- Updating service configurations

**Restart required** only when:
- Updating Traefik image
- Changing Traefik command-line flags
- Modifying docker-compose.yml

## Deployment Order

1. **First**: Deploy Traefik (creates ct-network)
2. **Second**: Deploy Portainer (joins ct-network)
3. **Third**: Deploy other stacks via Portainer UI

## Production Enhancements

For production use, consider:

- **HTTPS/TLS**: Configure Let's Encrypt for automatic SSL certificates
- **Dashboard Auth**: Enable authentication for dashboard
- **Access Logs**: Enable request logging
- **Metrics**: Export metrics to Prometheus
- **Middlewares**: Add rate limiting, IP whitelisting, etc.

## Resources

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
- [Routing Configuration](https://doc.traefik.io/traefik/routing/overview/)
- [Dashboard Reference](https://doc.traefik.io/traefik/operations/dashboard/)
