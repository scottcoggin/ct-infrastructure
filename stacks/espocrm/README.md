# EspoCRM Stack

Open-source CRM for personal relationship management with work associates, contacts, and opportunities.

## Overview

EspoCRM is a mature, feature-rich customer relationship management platform designed for personal and business use. This stack is configured for tracking interactions with work associates, managing contacts imported from LinkedIn/Facebook, and integrating with your email provider for communication via standard SMTP/IMAP protocols.

## Architecture

**Services:**
- **MySQL** (port 3306 internal): Database backend
- **EspoCRM** (port 8080): Main web application
- **EspoCRM Daemon**: Background jobs (email fetching, scheduled tasks)

**Resource Requirements:**
- RAM: ~1-2GB typical usage
- Disk: Database grows with contacts/activities
- CPU: Minimal (4 CPUs is more than sufficient)

**Integration:**
- Joins `ct-network` for Traefik routing
- Accessible at: http://espocrm.homenet24.lan
- n8n integration via `@traien/n8n-nodes-espocrm` package

## Quick Start

### 1. Environment Setup

```bash
cd stacks/espocrm
cp .env.example .env
# Edit .env with your passwords
```

**Required changes in .env:**
- `MYSQL_ROOT_PASSWORD`: Strong password for MySQL root user
- `MYSQL_PASSWORD`: Strong password for EspoCRM database user
- `ESPOCRM_ADMIN_PASSWORD`: Initial admin password (change after first login)

### 2. Deploy via Portainer

**Option A: Automatic GitOps (Recommended)**
1. Commit and push changes to GitHub
2. Portainer auto-detects and deploys within 5 minutes
3. Monitor via Portainer UI: Stacks → espocrm

**Option B: Manual Portainer Setup**
1. Navigate to Portainer UI: http://portainer.homenet24.lan
2. Stacks → Add stack → Git Repository
3. Repository URL: `https://github.com/scottcoggin/ct-infrastructure`
4. Compose path: `stacks/espocrm/docker-compose.yml`
5. Configure environment variables in Portainer UI
6. Deploy stack

### 3. First Access

1. Navigate to: http://espocrm.homenet24.lan
2. Login with credentials from `.env`:
   - Username: `admin` (or your configured value)
   - Password: (value from `ESPOCRM_ADMIN_PASSWORD`)
3. **Immediately change admin password** in Settings → Users

### 4. Initial Configuration

**User Profile:**
1. Click your profile icon → Preferences
2. Set your email address for notifications
3. Configure timezone and date/time format

**Personal Email Account:**
1. Settings → Personal Email Accounts → Create Account
2. See "Email Integration" section below for detailed setup

## Email Integration

EspoCRM supports email integration via standard SMTP (sending) and IMAP (receiving) protocols. This allows you to send and track emails directly from the CRM.

### Setup SMTP for Sending

**Step 1: Gather SMTP Credentials from Your Email Provider**

Consult your email provider's documentation for SMTP settings:
- SMTP server hostname (e.g., smtp.example.com)
- SMTP port (typically 465 for SSL, 587 for TLS/STARTTLS, 25 for unencrypted)
- Authentication method (usually username/password or app-specific password)
- Security protocol (SSL, TLS, STARTTLS, or None)

**Common providers:**
- Gmail: Use app-specific passwords (requires 2FA enabled)
- Outlook/Office 365: May require app passwords or OAuth
- Proton Mail: Requires SMTP tokens or Bridge (see appendix)
- Custom SMTP: Check your hosting provider's documentation

**Step 2: Configure in EspoCRM**

1. EspoCRM → Settings → Personal Email Accounts → Create Account
2. Fill in the form:
   - **Name**: Descriptive label (e.g., "Work Email")
   - **Email Address**: your@example.com
   - **SMTP Settings**:
     - Host: Your SMTP server hostname
     - Port: Your provider's SMTP port
     - Security: SSL, TLS, or None (match your provider's requirements)
     - Authentication: Enable if required (usually yes)
     - Username: Your email address or username
     - Password: Your email password or app-specific token
   - **IMAP**: Leave disabled for now (see optional setup below)
3. Click "Test Connection" to verify settings
4. Save

**Step 3: Set as Default**

1. Settings → Personal Email Accounts
2. Click on your configured account → Set as Default

### Setup IMAP for Receiving (Optional)

If you want to receive and track incoming emails in EspoCRM:

**Step 1: Gather IMAP Credentials**

Check your email provider's documentation for:
- IMAP server hostname
- IMAP port (typically 993 for SSL, 143 for TLS)
- Security protocol

**Step 2: Configure in EspoCRM**

1. Edit your Personal Email Account
2. Enable IMAP and fill in:
   - Host: Your IMAP server hostname
   - Port: Your provider's IMAP port
   - Security: SSL or TLS
   - Username: Usually same as SMTP username
   - Password: Usually same as SMTP password
3. Test Connection → Save

**Step 3: Configure Fetch Settings**

1. Set check frequency (e.g., every 5 minutes)
2. Choose which folders to monitor
3. Configure email-to-case or email-to-contact matching rules

**Note:** Many users only need SMTP for sending. IMAP is optional and adds background email polling. For provider-specific examples, see the appendix.

## n8n Integration

Automate contact imports, lead generation, and workflows using n8n.

### Install EspoCRM Node in n8n

```bash
# SSH into docker host
ssh root@docker.homenet24.lan

# Access n8n container
docker exec -it n8n sh

# Install EspoCRM community node
npm install @traien/n8n-nodes-espocrm

# Restart n8n
exit
docker restart n8n
```

### Configure API Credentials in n8n

1. **Create API User in EspoCRM:**
   - Settings → API Users → Create API User
   - Username: `n8n_integration`
   - Enable "API Enabled"
   - Generate API Key (copy this)

2. **Add Credentials in n8n:**
   - n8n → Credentials → Add Credential
   - Search "EspoCRM"
   - URL: `http://espocrm:80` (internal Docker network)
   - API Key: (paste from EspoCRM)
   - Test & Save

### Example Workflows

**Workflow 1: LinkedIn Contacts Import**
- Trigger: Manual or scheduled
- Read CSV file (LinkedIn export)
- Parse and deduplicate contacts
- Create/update contacts in EspoCRM
- See: `n8n-workflows/linkedin-contacts-import.json`

**Workflow 2: Facebook Contacts Import**
- Similar to LinkedIn workflow
- Map Facebook fields to EspoCRM schema
- Handle profile pictures (optional)

**Workflow 3: Email Follow-up Reminders**
- Trigger: Daily schedule
- Query EspoCRM for contacts without recent activity
- Send reminder notification (email/Slack)

## Contact Import (LinkedIn/Facebook)

### Export Contacts from LinkedIn

1. LinkedIn → Me → Settings & Privacy
2. Data Privacy → Get a copy of your data
3. Select "Connections" → Request Archive
4. Download CSV when ready (may take hours)

### Export Contacts from Facebook

1. Facebook → Settings → Your Facebook Information
2. Download Your Information
3. Select "Friends and Followers" → Create File
4. Download JSON/CSV when ready

### Import via n8n Workflow

See example workflow: `stacks/espocrm/n8n-workflows/linkedin-contacts-import.json`

**Workflow steps:**
1. Upload CSV to n8n (via webhook or file upload)
2. Parse CSV rows
3. Map fields:
   - LinkedIn "First Name" → EspoCRM "firstName"
   - LinkedIn "Last Name" → EspoCRM "lastName"
   - LinkedIn "Company" → EspoCRM "accountName"
   - LinkedIn "Position" → EspoCRM "title"
   - LinkedIn "Email Address" → EspoCRM "emailAddress"
4. Deduplicate by email address
5. Create or update contacts in EspoCRM

### Manual Import (Alternative)

1. EspoCRM → Contacts → Import
2. Upload CSV file
3. Map columns to EspoCRM fields
4. Configure duplicate handling
5. Import

## Service Management

### Start/Stop Services

```bash
# On remote host (via SSH)
ssh root@docker.homenet24.lan "cd /data/compose/1/stacks/espocrm && docker compose up -d"
ssh root@docker.homenet24.lan "cd /data/compose/1/stacks/espocrm && docker compose down"

# Check status
ssh root@docker.homenet24.lan "docker ps | grep espocrm"
```

### View Logs

```bash
# All services
ssh root@docker.homenet24.lan "docker logs espocrm -f"

# MySQL
ssh root@docker.homenet24.lan "docker logs espocrm-mysql -f"

# Daemon
ssh root@docker.homenet24.lan "docker logs espocrm-daemon -f"
```

### Restart Services

```bash
# Restart main application
ssh root@docker.homenet24.lan "docker restart espocrm"

# Restart all services
ssh root@docker.homenet24.lan "cd /data/compose/1/stacks/espocrm && docker compose restart"
```

## Backup and Restore

### Backup

**Database Backup:**
```bash
# Export MySQL database
ssh root@docker.homenet24.lan "docker exec espocrm-mysql mysqldump -u root -p\$MYSQL_ROOT_PASSWORD espocrm > /root/backups/espocrm_$(date +%Y%m%d).sql"

# Download backup
scp root@docker.homenet24.lan:/root/backups/espocrm_*.sql ./backups/
```

**Application Data Backup:**
```bash
# Backup EspoCRM files (attachments, custom configs)
ssh root@docker.homenet24.lan "docker run --rm -v espocrm_espocrm_data:/data -v /root/backups:/backup alpine tar czf /backup/espocrm_data_$(date +%Y%m%d).tar.gz /data"

# Download backup
scp root@docker.homenet24.lan:/root/backups/espocrm_data_*.tar.gz ./backups/
```

### Restore

**Database Restore:**
```bash
# Upload backup to remote host
scp ./backups/espocrm_20250115.sql root@docker.homenet24.lan:/root/backups/

# Import database
ssh root@docker.homenet24.lan "docker exec -i espocrm-mysql mysql -u root -p\$MYSQL_ROOT_PASSWORD espocrm < /root/backups/espocrm_20250115.sql"

# Restart services
ssh root@docker.homenet24.lan "docker restart espocrm espocrm-daemon"
```

**Application Data Restore:**
```bash
# Upload backup
scp ./backups/espocrm_data_20250115.tar.gz root@docker.homenet24.lan:/root/backups/

# Stop services
ssh root@docker.homenet24.lan "cd /data/compose/1/stacks/espocrm && docker compose down"

# Restore volume
ssh root@docker.homenet24.lan "docker run --rm -v espocrm_espocrm_data:/data -v /root/backups:/backup alpine sh -c 'cd /data && tar xzf /backup/espocrm_data_20250115.tar.gz --strip 1'"

# Restart services
ssh root@docker.homenet24.lan "cd /data/compose/1/stacks/espocrm && docker compose up -d"
```

## Troubleshooting

### EspoCRM Won't Start

**Check database connection:**
```bash
ssh root@docker.homenet24.lan "docker logs espocrm | grep -i error"
ssh root@docker.homenet24.lan "docker logs espocrm-mysql | grep -i error"
```

**Verify MySQL is healthy:**
```bash
ssh root@docker.homenet24.lan "docker exec espocrm-mysql mysqladmin ping -u root -p\$MYSQL_ROOT_PASSWORD"
```

### Can't Login

**Option 1: Reset password via CLI (Preserves Data)**
```bash
# Access EspoCRM container
ssh root@docker.homenet24.lan "docker exec -it espocrm bash"

# Inside container:
cd /var/www/html
php command.php set-password [username]
# Follow prompts to set new password
exit
```

**Option 2: Full Reset with New Password (Destructive)**

If you need to reset the entire installation and apply new environment variables:

```bash
# WARNING: This deletes ALL CRM data (contacts, deals, emails, etc.)

# 1. Stop and delete all volumes
ssh root@docker.homenet24.lan "docker compose -p espocrm down -v"

# 2. Update ESPOCRM_ADMIN_PASSWORD in Portainer UI:
#    Portainer → Stacks → espocrm → Editor → Environment variables
#    Update the password and click "Pull and redeploy"

# 3. Verify deployment
ssh root@docker.homenet24.lan "docker ps | grep espocrm"
```

**Note:** `ESPOCRM_ADMIN_PASSWORD` is only read during **first startup**. Changing it in Portainer doesn't update an existing admin account - the password becomes part of the persistent application state.

### Email Not Sending

**Check SMTP settings:**
1. EspoCRM → Settings → Personal Email Accounts
2. Edit your account → Test Connection
3. Verify credentials and settings match your provider's requirements

**Common issues:**
- Wrong credentials: Verify username/password or app-specific password
- Wrong port/security: Check your provider's documentation (SSL vs TLS vs STARTTLS)
- Authentication required: Enable SMTP authentication
- Firewall blocking: Ensure Docker container can reach SMTP server
- Rate limiting: Some providers limit sending frequency

**Test from command line:**
```bash
# Install testing tool
ssh root@docker.homenet24.lan "docker exec espocrm apt update && apt install -y swaks"

# Test SMTP connection (replace with your settings)
ssh root@docker.homenet24.lan "docker exec espocrm swaks \
  --to recipient@example.com \
  --from your@example.com \
  --server smtp.example.com:587 \
  --auth LOGIN \
  --auth-user your@example.com \
  --auth-password 'YOUR_PASSWORD' \
  --tls"
```

**Check EspoCRM logs:**
```bash
ssh root@docker.homenet24.lan "docker logs espocrm | grep -i email"
```

### Daemon Not Running

**Check daemon logs:**
```bash
ssh root@docker.homenet24.lan "docker logs espocrm-daemon -f"
```

**Restart daemon:**
```bash
ssh root@docker.homenet24.lan "docker restart espocrm-daemon"
```

### Port Conflicts

If port 8080 is already in use:

1. **Update via Portainer UI:**
   - Stacks → espocrm → Environment Variables
   - Change `ESPOCRM_PORT=8081`
   - Redeploy stack

2. **Or edit local .env:**
   ```bash
   ESPOCRM_PORT=8081
   ```
   - Commit and push to trigger GitOps deployment

## Common Operations

### Update EspoCRM

```bash
# Pull latest image
ssh root@docker.homenet24.lan "cd /data/compose/1/stacks/espocrm && docker compose pull espocrm"

# Restart with new image
ssh root@docker.homenet24.lan "cd /data/compose/1/stacks/espocrm && docker compose up -d"
```

### Access MySQL Database

```bash
# Connect to MySQL CLI
ssh root@docker.homenet24.lan "docker exec -it espocrm-mysql mysql -u espocrm -p espocrm"

# Run query
ssh root@docker.homenet24.lan "docker exec espocrm-mysql mysql -u espocrm -p\$MYSQL_PASSWORD espocrm -e 'SELECT COUNT(*) FROM contact;'"
```

### Clear Cache

```bash
# Clear EspoCRM cache
ssh root@docker.homenet24.lan "docker exec espocrm rm -rf /var/www/html/data/cache/*"
ssh root@docker.homenet24.lan "docker restart espocrm"
```

### Enable Debug Mode

1. EspoCRM → Administration → Settings
2. Scroll to "Developer" section
3. Enable "Log Level" → Debug
4. View logs: `docker logs espocrm -f`

## Integration with Other Stacks

### DataLab Integration (Optional)

Store CRM analytics in DataMart:

```sql
-- Example: Export contacts to DataMart
-- Run via Mage pipeline or n8n workflow
INSERT INTO datamart.01_bronze.bronze_crm_contacts
SELECT id, first_name, last_name, email_address, created_at
FROM espocrm.contact;
```

### n8n Workflows with Other Stacks

**Example: CRM → OpenWebUI**
- Query contacts needing follow-up
- Generate personalized email drafts using LLM
- Send via EspoCRM email

**Example: CRM → DataLab**
- Export contact activity daily
- Transform in Mage (silver layer)
- Visualize in Superset dashboard

## Security Notes

1. **Change default passwords immediately**
2. **Backup N8N_ENCRYPTION_KEY** if using n8n for CRM workflows
3. **Secure email credentials** - use app-specific passwords when available
4. **Regular backups:** Database + file attachments
5. **API keys:** Rotate periodically, use least privilege

## Appendix: Provider-Specific Email Examples

### Proton Mail SMTP Configuration

Proton Mail requires special configuration due to its end-to-end encryption:

**Option 1: SMTP Tokens (Recommended for Custom Domains)**

Prerequisites:
- Proton Mail paid plan (Mail Plus, Unlimited, or Business)
- Custom domain email address (SMTP tokens don't work with @proton.me addresses)

Setup:
1. Log into Proton Mail: https://mail.proton.me
2. Settings → All settings → Proton Mail → IMAP/SMTP
3. Scroll to "SMTP tokens" section → Click "Create token"
4. Copy the generated token

Configure in EspoCRM:
- Host: `smtp.protonmail.ch`
- Port: `587`
- Security: `TLS` (STARTTLS)
- Authentication: `true`
- Username: your@customdomain.com
- Password: (paste SMTP token)

**Option 2: Proton Mail Bridge (For @proton.me Addresses or IMAP)**

Prerequisites:
- Proton Mail paid plan
- Desktop application (Windows, macOS, Linux)

Setup:
1. Download Proton Mail Bridge: https://proton.me/mail/bridge
2. Install and launch Bridge
3. Add your Proton Mail account to Bridge
4. Bridge provides local IMAP/SMTP server with credentials

Configure in EspoCRM:
- SMTP Host: `127.0.0.1` (or Bridge machine IP if remote)
- SMTP Port: `1025` (Bridge default)
- IMAP Host: `127.0.0.1`
- IMAP Port: `1143` (Bridge default)
- Security: `TLS`
- Username/Password: Provided by Bridge application

Note: Bridge must remain running for email to work.

### Gmail SMTP Configuration

Prerequisites:
- Gmail account with 2-Factor Authentication enabled
- App-specific password generated

Setup:
1. Google Account → Security → 2-Step Verification → App passwords
2. Generate app password for "Mail"

Configure in EspoCRM:
- Host: `smtp.gmail.com`
- Port: `587`
- Security: `TLS` (STARTTLS)
- Authentication: `true`
- Username: your@gmail.com
- Password: (16-character app password)

### Outlook/Office 365 SMTP Configuration

Configure in EspoCRM:
- Host: `smtp.office365.com`
- Port: `587`
- Security: `TLS` (STARTTLS)
- Authentication: `true`
- Username: your@outlook.com
- Password: Your account password or app password

Note: Some Office 365 accounts may require app-specific passwords or OAuth (check your organization's settings).

## Documentation References

- EspoCRM Docs: https://docs.espocrm.com/
- Proton Mail SMTP: https://proton.me/support/smtp-submission
- n8n EspoCRM Node: https://www.npmjs.com/package/@traien/n8n-nodes-espocrm
- LinkedIn Export: https://www.linkedin.com/help/linkedin/answer/a566336

## Support

- EspoCRM Forum: https://forum.espocrm.com/
- GitHub Issues (this repo): https://github.com/scottcoggin/ct-infrastructure/issues
- n8n Community: https://community.n8n.io/
