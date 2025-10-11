# n8n - Workflow Automation Platform

A self-hosted workflow automation platform for connecting apps, services, and APIs. Build complex automation workflows with a visual editor and hundreds of integrations.

## Architecture

- **n8n** - Workflow automation engine with visual editor
- **PostgreSQL** - Workflow and credential storage with encryption

## Features

- **Visual Workflow Builder**: Drag-and-drop interface for creating automation workflows
- **500+ Integrations**: Connect to popular services, APIs, and databases
- **Self-Hosted**: Full control over your data and workflows
- **Webhook Support**: Trigger workflows from external services
- **Scheduling**: Run workflows on a schedule (cron-based)
- **Credential Encryption**: Secure storage of API keys and passwords
- **JavaScript Support**: Execute custom code in your workflows

## Requirements

- Docker Engine 20.10+
- Docker Compose v2.0+
- Minimum 2GB RAM (4GB recommended)
- 10GB available disk space

## Quick Start

### 1. Clone and Setup

```bash
# Navigate to the project directory
cd stacks/n8n

# Copy environment template
cp .env.example .env

# Edit .env file with your preferences
nano .env
```

**Important:** Generate a secure encryption key for n8n:
```bash
openssl rand -base64 32
```
Copy the output and set it as `N8N_ENCRYPTION_KEY` in your `.env` file.

**CRITICAL: Backup your N8N_ENCRYPTION_KEY**
- Without this key, you cannot recover stored credentials
- Store it securely (password manager, encrypted backup, etc.)
- If you lose this key, you'll need to re-enter all workflow credentials

### 2. Start the Services

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Check status
docker compose ps
```

### 3. Wait for Initialization

First startup takes 1-2 minutes:
- PostgreSQL initializes database and creates n8n user
- n8n runs database migrations
- n8n starts and becomes available

### 4. Access n8n

| Service    | URL                        | Default Credentials      |
|------------|----------------------------|--------------------------|
| n8n        | http://n8n.homenet24.lan   | Create on first access   |
| PostgreSQL | localhost:5678             | (see .env)               |

**First Access:**
1. Navigate to http://n8n.homenet24.lan
2. Create your admin account (email + password)
3. Start building workflows!

## Integration with Existing Stacks

### DataLab Integration

**Trigger Mage Pipelines from n8n:**
```javascript
// In n8n HTTP Request node:
// Method: POST
// URL: http://mage:6789/api/pipeline_schedules/[id]/pipeline_runs

// Trigger data processing workflows from n8n
// Use case: Run ETL pipeline when file uploaded to cloud storage
```

**Query DataMart from n8n:**
```javascript
// In n8n Postgres node:
// Host: datalab-postgres
// Port: 5432
// Database: datamart
// Schema: 03_gold

// Use case: Read analytics data and send reports via email/Slack
```

### OpenWebUI Integration

**Automate LLM Workflows:**
```javascript
// In n8n HTTP Request node:
// Method: POST
// URL: http://open-webui:8080/api/v1/chat/completions

// Use case: Process documents with AI and store results
```

### Common Integration Patterns

1. **Scheduled Data Processing**
   - Trigger: Schedule (daily, hourly, etc.)
   - Action: Run Mage pipeline, check results
   - Notification: Send Slack message on completion

2. **Event-Driven Workflows**
   - Trigger: Webhook (external service)
   - Action: Process data with LLM via OpenWebUI
   - Storage: Write results to DataMart

3. **Monitoring & Alerts**
   - Trigger: Schedule (every 5 minutes)
   - Action: Query DataMart for data quality metrics
   - Alert: Send notification if threshold exceeded

## Common Operations

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f n8n
docker compose logs -f postgres
```

### Restart Services

```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart n8n
```

### Stop Services

```bash
# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes all workflows and credentials)
docker compose down -v
```

### Access PostgreSQL CLI

```bash
docker compose exec postgres psql -U n8n -d n8n
```

Useful commands:
```sql
-- List all tables
\dt

-- View workflow executions
SELECT * FROM execution_entity ORDER BY "startedAt" DESC LIMIT 10;

-- View stored credentials (encrypted)
SELECT * FROM credentials_entity;

-- Database size
\l+
```

### Backup and Restore

**Backup n8n Data:**
```bash
# Backup database
docker compose exec postgres pg_dump -U n8n n8n > n8n_backup.sql

# Backup encryption key (CRITICAL!)
# Copy N8N_ENCRYPTION_KEY from .env to secure location
```

**Restore n8n Data:**
```bash
# Restore database
docker compose exec -T postgres psql -U n8n n8n < n8n_backup.sql

# Restore encryption key
# Update N8N_ENCRYPTION_KEY in .env with backed up value
docker compose restart n8n
```

## Workflow Development

### Building Your First Workflow

1. **Access n8n Editor**: http://n8n.homenet24.lan
2. **Click "Add Workflow"**
3. **Add Trigger Node**:
   - Schedule: Run on a schedule
   - Webhook: Trigger from external service
   - Manual: Run manually for testing

4. **Add Action Nodes**:
   - HTTP Request: Call any REST API
   - Database: Query PostgreSQL, MySQL, etc.
   - Transform: Process data with JavaScript
   - Notification: Send to Slack, email, etc.

5. **Connect Nodes**: Drag between node outputs/inputs
6. **Test**: Click "Execute Workflow"
7. **Activate**: Toggle "Active" switch

### Example: Daily DataMart Report

```
[Schedule Trigger: Daily 9 AM]
    ↓
[Postgres Node: Query 03_gold.fact_sales]
    ↓
[Function Node: Calculate totals]
    ↓
[Email Node: Send report to team]
```

### Example: File Upload Processing

```
[Webhook Trigger: Receive upload notification]
    ↓
[HTTP Request: Download file]
    ↓
[HTTP Request: Trigger Mage bronze pipeline]
    ↓
[Slack Node: Send confirmation]
```

## Configuration

### Webhook URL

For external services to trigger n8n workflows:
- **Production**: Set `WEBHOOK_URL=http://n8n.homenet24.lan` in .env
- **Public**: Use Cloudflare Tunnel or reverse proxy with HTTPS

### Timezone

Set timezone for scheduling in `.env`:
```bash
TZ=America/New_York
```

### Basic Authentication (Optional)

Add extra security layer by enabling basic auth:

1. Uncomment in `.env`:
```bash
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_password
```

2. Uncomment in `docker-compose.yml`:
```yaml
- N8N_BASIC_AUTH_ACTIVE=${N8N_BASIC_AUTH_ACTIVE:-false}
- N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
- N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
```

3. Restart: `docker compose restart n8n`

## Troubleshooting

### n8n won't start

```bash
# Check PostgreSQL is running
docker compose ps postgres

# Check database connection
docker compose exec postgres psql -U n8n -d n8n -c "\conninfo"

# View n8n logs
docker compose logs n8n
```

### Database connection failed

```bash
# Verify credentials match
docker compose exec postgres psql -U n8n -d n8n

# Check environment variables
docker compose exec n8n env | grep DB_POSTGRES
```

### Lost encryption key

If you lose your `N8N_ENCRYPTION_KEY`:
- **Cannot recover**: Existing credentials are permanently encrypted
- **Solution**: Generate new key, re-enter all credentials in workflows
- **Prevention**: Always backup your encryption key!

### Workflows not executing

```bash
# Check execution mode
docker compose exec n8n env | grep EXECUTIONS_MODE

# View execution logs in n8n UI
# Navigate to: Executions tab in n8n interface

# Check for errors in logs
docker compose logs -f n8n
```

### Port conflicts

If port 5678 is already in use, modify in `.env`:
```bash
N8N_PORT=5679
```

Then restart:
```bash
docker compose down
docker compose up -d
```

## Maintenance

### Update n8n

```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d

# Check version
docker compose exec n8n n8n --version
```

### Clean Up Execution History

Execution history can grow large over time. Clean up via n8n UI:
- Settings → Executions → Prune executions
- Or manually in database:
```sql
DELETE FROM execution_entity WHERE "startedAt" < NOW() - INTERVAL '30 days';
```

## Project Structure

```
n8n/
├── docker-compose.yml          # Service orchestration
├── .env                        # Environment variables (not in git)
├── .env.example               # Environment template
├── init-data.sh               # Database initialization
└── README.md                  # This file
```

## Security Considerations

- Change all default passwords
- Use strong `N8N_ENCRYPTION_KEY` (generate with `openssl rand -base64 32`)
- **BACKUP your encryption key** - you cannot recover credentials without it
- Don't commit `.env` to version control
- Use HTTPS in production (Cloudflare Tunnel, Let's Encrypt, etc.)
- Enable basic auth if exposing to internet
- Regularly backup n8n database
- Review workflow permissions and credentials

## Available Integrations

n8n supports 500+ integrations including:

**Communication**: Slack, Discord, Email, SMS, Telegram
**Cloud Storage**: AWS S3, Google Drive, Dropbox
**Databases**: PostgreSQL, MySQL, MongoDB, Redis
**APIs**: HTTP Request, GraphQL, REST
**Data**: CSV, JSON, XML, Excel
**CRM**: Salesforce, HubSpot, Pipedrive
**Development**: GitHub, GitLab, Jira
**AI/ML**: OpenAI, Anthropic (via HTTP), HuggingFace

...and many more!

## Next Steps

1. Start the environment
2. Create your admin account
3. Build your first workflow
4. Integrate with DataLab for automated ETL
5. Connect to OpenWebUI for AI-powered workflows
6. Set up monitoring and alerting workflows

## Resources

- [n8n Documentation](https://docs.n8n.io)
- [n8n Community](https://community.n8n.io)
- [Workflow Templates](https://n8n.io/workflows)
- [Integration Nodes](https://n8n.io/integrations)

## License

This is a home lab setup for learning and experimentation. Modify and use as needed.

## Contributing

This is a personal home lab project. Feel free to fork and customize for your own use!
