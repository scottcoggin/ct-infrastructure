# Self-Hosted GitHub Actions Runner Setup

This repository uses a **self-hosted GitHub Actions runner** running on `docker.homenet24.lan` for automated deployments.

## Why Self-Hosted?

The home lab is behind NAT/firewall, so GitHub's cloud runners cannot reach:
- `docker.homenet24.lan` (local DNS)
- `10.0.0.4` (private network address)

A self-hosted runner runs **on your local network** and can access all local resources directly.

## Quick Setup

### 1. Run the Installation Script

**On your local machine (with SSH access to docker.homenet24.lan):**

```bash
# Copy the installation script to the Docker host
scp scripts/install-github-runner.sh root@docker.homenet24.lan:/tmp/

# SSH to the Docker host
ssh root@docker.homenet24.lan

# Run the installation script
sudo bash /tmp/install-github-runner.sh
```

The script will:
1. Prompt you for a registration token from GitHub
2. Download and install the GitHub Actions runner
3. Configure it to connect to this repository
4. Install it as a systemd service (auto-starts on boot)
5. Start the runner

### 2. Get Registration Token

When prompted by the script, get your token here:

**https://github.com/scottcoggin/ct-infrastructure/settings/actions/runners/new**

1. Select **"Linux"** as operating system
2. Copy the token from the configuration command shown
3. Paste it when the script prompts you

**Note:** Tokens expire after 1 hour. If your token expires, generate a new one and re-run the script.

### 3. Verify Runner is Active

After installation:

1. Go to: **https://github.com/scottcoggin/ct-infrastructure/settings/actions/runners**
2. You should see your runner listed as:
   - **Status:** Idle (green checkmark) or Active (running a job)
   - **Name:** The hostname of the Docker host
   - **Labels:** self-hosted, Linux, X64

## How It Works

### Workflow Process

```
1. Push to stacks/datalab/ → GitHub detects change
2. GitHub → Sends job to self-hosted runner
3. Runner (on docker.homenet24.lan) → Downloads code
4. Runner → Copies files to /root/docker/apps/datalab/
5. Portainer (5-minute poll) → Detects git change
6. Portainer → Pulls latest docker-compose.yml
7. Portainer → Recreates containers with new config
```

### No SSH Needed!

Because the runner runs directly on `docker.homenet24.lan`, it can copy files locally:

```yaml
# Old way (cloud runner):
scp -i ~/.ssh/id_rsa stacks/datalab/cube/cube.js root@docker.homenet24.lan:/root/docker/apps/datalab/cube/

# New way (self-hosted runner):
cp stacks/datalab/cube/cube.js /root/docker/apps/datalab/cube/
```

Much simpler and faster!

## GitHub Secrets

### Required Secrets

**None!**

The runner runs directly on the Docker host, so no SSH keys or host addresses are needed.

### Cleanup Old Secrets

You can delete these secrets (no longer used):
- `DOCKER_HOST`
- `DOCKER_HOST_SSH_KEY`
- `PORTAINER_WEBHOOK_DATALAB`

Go to: **Settings → Secrets and variables → Actions**

## Testing the Setup

### Manual Trigger

Test the runner without pushing code:

1. Go to: **Actions → Deploy DataLab Stack**
2. Click **"Run workflow"** dropdown
3. Select branch: **main**
4. Click **"Run workflow"** button

Watch the workflow run in real-time!

### Push Test Change

```bash
# Make a small change
echo "# Test deployment" >> stacks/datalab/cube/README.md

# Commit and push
git add stacks/datalab/cube/README.md
git commit -m "Test self-hosted runner deployment"
git push

# Watch at: GitHub → Actions tab
```

## Managing the Runner

### Check Runner Status

```bash
ssh root@docker.homenet24.lan
cd /root/actions-runner
sudo ./svc.sh status
```

### View Runner Logs

```bash
# Real-time logs
ssh root@docker.homenet24.lan
sudo journalctl -u actions.runner.* -f

# Last 100 lines
sudo journalctl -u actions.runner.* -n 100
```

### Stop/Start Runner

```bash
ssh root@docker.homenet24.lan
cd /root/actions-runner

# Stop
sudo ./svc.sh stop

# Start
sudo ./svc.sh start

# Restart
sudo ./svc.sh stop && sudo ./svc.sh start
```

### Update Runner

When GitHub releases a new runner version:

```bash
ssh root@docker.homenet24.lan
cd /root/actions-runner

# Stop service
sudo ./svc.sh stop

# Download new version
curl -o actions-runner-linux-x64-2.xxx.x.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.xxx.x/actions-runner-linux-x64-2.xxx.x.tar.gz

# Extract (replaces old files)
tar xzf ./actions-runner-linux-x64-2.xxx.x.tar.gz

# Start service
sudo ./svc.sh start
```

### Uninstall Runner

```bash
ssh root@docker.homenet24.lan
cd /root/actions-runner

# Stop and uninstall service
sudo ./svc.sh stop
sudo ./svc.sh uninstall

# Remove runner directory
cd /root
rm -rf actions-runner
```

Then remove the runner from GitHub:
- Settings → Actions → Runners → Click runner → Remove

## Troubleshooting

### Runner Shows Offline

**Check if service is running:**
```bash
ssh root@docker.homenet24.lan
sudo systemctl status actions.runner.*
```

**Restart the service:**
```bash
cd /root/actions-runner
sudo ./svc.sh stop && sudo ./svc.sh start
```

**Check logs for errors:**
```bash
sudo journalctl -u actions.runner.* -n 50
```

### Workflow Fails with Permission Denied

The runner needs write access to `/root/docker/apps/datalab/`.

**Check permissions:**
```bash
ssh root@docker.homenet24.lan
ls -la /root/docker/apps/datalab/
```

**Fix permissions:**
```bash
chmod 755 /root/docker/apps
chmod 755 /root/docker/apps/datalab
```

### Runner Not Picking Up Jobs

**Verify runner labels match workflow:**
- Workflow says: `runs-on: self-hosted`
- Runner must have label: `self-hosted`

**Check in GitHub UI:**
- Settings → Actions → Runners → View runner labels

### Registration Token Expired

Tokens expire after 1 hour. Generate a new one:

https://github.com/scottcoggin/ct-infrastructure/settings/actions/runners/new

Then re-run the installation script.

## Security Considerations

### Runner Permissions

The runner runs as **root** on the Docker host and has:
- Full access to `/root/docker/apps/`
- Access to all GitHub secrets
- Ability to execute arbitrary commands from workflows

### Best Practices

1. **Review workflow changes carefully** - Anyone who can push to main can execute code on your Docker host
2. **Use branch protection** - Require PR reviews before merging to main
3. **Monitor runner logs** - Watch for suspicious activity
4. **Keep runner updated** - Apply security patches promptly

### If Compromised

If you suspect the runner has been compromised:

1. **Immediately remove runner** from GitHub UI
2. **Stop the service:** `sudo ./svc.sh stop`
3. **Check logs:** `sudo journalctl -u actions.runner.* | grep -i suspicious`
4. **Audit recent workflow runs:** GitHub → Actions tab
5. **Rotate secrets:** Delete and recreate any secrets
6. **Rebuild runner:** Uninstall, reinstall with new token

## Additional Resources

- [GitHub Actions self-hosted runner docs](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Runner security hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [Workflow syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
