# Security Policy

## Reporting Security Vulnerabilities

If you discover a security vulnerability in this project, please report it by creating a GitHub Issue or contacting the repository maintainers directly.

**Please do not publicly disclose the vulnerability until it has been addressed.**

## Security Best Practices

This repository contains Docker Compose configurations for home lab infrastructure. When deploying:

### Secrets Management
- Never commit `.env` files to version control
- Use strong, randomly generated passwords and API keys
- Generate secret keys using: `openssl rand -base64 42`
- Backup encryption keys securely (especially `N8N_ENCRYPTION_KEY`)

### Network Security
- This infrastructure is designed for **private local networks only**
- Do not expose services directly to the internet without proper security measures
- For external access, use:
  - VPN (WireGuard, Tailscale)
  - Cloudflare Tunnel
  - Properly configured reverse proxy with HTTPS/TLS

### Access Control
- Change all default passwords immediately after deployment
- Enable 2FA where available (Portainer, n8n)
- Use strong admin credentials
- Restrict access to management interfaces (Portainer, Traefik dashboard)

### Container Security
- Keep Docker images up to date
- Review and understand what each container does before deploying
- Docker socket is mounted read-only (`:ro`) where possible
- Services run with minimal required privileges

### Database Security
- PostgreSQL is not exposed externally by default
- Use unique passwords for each database instance
- Regularly backup databases
- Encrypt backups of sensitive data

### API Keys
- Store API keys in environment variables, never in code
- Rotate API keys periodically
- Use separate API keys for development and production
- Monitor API usage for unusual activity

## Known Limitations

This is a **home lab configuration**, not a production-ready setup. It prioritizes ease of use and learning over enterprise-grade security:

- Traefik dashboard has no authentication (should be restricted in production)
- Services use HTTP, not HTTPS (add TLS certificates for production)
- No rate limiting or DDoS protection
- No intrusion detection or monitoring
- Designed for trusted local networks only

## Security Updates

- Monitor GitHub Security Advisories for this repository
- Subscribe to security announcements for:
  - [Docker](https://docs.docker.com/security/)
  - [Traefik](https://github.com/traefik/traefik/security)
  - [Portainer](https://github.com/portainer/portainer/security)
  - Individual stack components (Mage, Superset, n8n, etc.)

## Disclaimer

This software is provided "as is" without warranty of any kind. Users are responsible for securing their own deployments. See the LICENSE file for full terms.
